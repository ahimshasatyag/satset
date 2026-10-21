import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/supabase_config.dart';
import '../../../../app/constants/database_constants.dart';
import '../models/user_model.dart';
import '../utils/otp_generator.dart';
import '../utils/password_hasher.dart';
import '../utils/validators.dart';

/// Kontrak Remote Data Source untuk autentikasi pengguna
abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
  });

  Future<UserModel> loginWithGoogle();

  Future<void> forgotPassword(String email);

  Future<void> verifyResetCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> resendVerificationCode(String email);

  Future<void> logout();
}

/// Implementasi Remote Data Source dengan integrasi tabel PostgreSQL `m_users` di Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient? _customClient;

  AuthRemoteDataSourceImpl({SupabaseClient? client}) : _customClient = client;

  bool get _isSupabaseAvailable {
    if (_customClient != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  bool _isJwtExpired(dynamic e) {
    if (e is PostgrestException) {
      final msg = e.message.toLowerCase();
      return e.code == 'PGRST303' ||
          msg.contains('jwt expired') ||
          msg.contains('pgrst303');
    }
    return false;
  }

  /// Memastikan sesi Supabase Auth yang sudah kadaluarsa dibersihkan agar query publik berhasil
  Future<void> _sanitizeSession() async {
    if (!_isSupabaseAvailable) return;
    try {
      final session = _client.auth.currentSession;
      if (session != null && session.isExpired) {
        try {
          await _client.auth.refreshSession();
        } catch (_) {
          await _client.auth.signOut();
        }
      }
    } catch (_) {}
  }

  /// Menjalankan operasi Supabase dengan pemulihan otomatis jika token JWT kadaluarsa (PGRST303)
  Future<T> _executeWithSessionRecovery<T>(Future<T> Function() action) async {
    await _sanitizeSession();
    try {
      return await action();
    } catch (e) {
      if (_isJwtExpired(e)) {
        try {
          await _client.auth.signOut();
        } catch (_) {}
        return await action();
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Validasi format email dan kata sandi menggunakan Validators
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    if (_isSupabaseAvailable) {
      try {
        final response = await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        });

        if (response == null) {
          throw Exception('Email belum terdaftar pada sistem SatSet.');
        }

        final storedHashedPassword =
            response[UserTableColumns.password] as String?;
        if (storedHashedPassword != null && storedHashedPassword.isNotEmpty) {
          final isPasswordValid = PasswordHasher.verify(
            password,
            storedHashedPassword,
          );
          if (!isPasswordValid) {
            throw Exception('Kata sandi yang Anda masukkan salah.');
          }
        }

        // Perbarui lokasi pengguna terkini di database Supabase jika koordinat tersedia
        if (latitude != null && longitude != null) {
          try {
            await _client.from(DatabaseConstants.tableUsers).update({
              UserTableColumns.latitude: latitude,
              UserTableColumns.longitude: longitude,
              UserTableColumns.updatedAt:
                  DateTime.now().toUtc().toIso8601String(),
            }).eq(UserTableColumns.id, response[UserTableColumns.id]);

            response[UserTableColumns.latitude] = latitude;
            response[UserTableColumns.longitude] = longitude;
          } catch (_) {}
        }

        return UserModel.fromDatabase(response);
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Kesalahan basis data Supabase: ${e.message}');
        }
        rethrow;
      }
    }

    // Fallback simulasi jika berjalan di lingkungan tanpa Supabase (misal testing)
    await Future.delayed(const Duration(milliseconds: 600));

    return UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanEmail.split('@').first.toUpperCase(),
      email: cleanEmail,
      phone: '+6281234567890',
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();
    final cleanName = name.trim();
    final cleanAlamat = alamatLengkap?.trim();

    // Validasi data pendaftaran menggunakan Validators
    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final phoneError = Validators.validatePhone(cleanPhone);
    if (phoneError != null) throw Exception(phoneError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    if (_isSupabaseAvailable) {
      try {
        // 1. Cek apakah email sudah terdaftar
        final existingUser = await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .select(UserTableColumns.id)
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        });

        if (existingUser != null) {
          throw Exception(
            'Email sudah terdaftar. Silakan gunakan email lain atau masuk.',
          );
        }

        // 2. Hash kata sandi untuk keamanan penyimpanan di basis data
        final hashedPassword = PasswordHasher.hash(password);

        // 3. Simpan data ke tabel m_users di Supabase
        final newUserData = {
          UserTableColumns.namaLengkap: cleanName,
          UserTableColumns.email: cleanEmail,
          UserTableColumns.noHp: cleanPhone,
          UserTableColumns.password: hashedPassword,
          UserTableColumns.alamatLengkap: cleanAlamat,
          UserTableColumns.latitude: latitude,
          UserTableColumns.longitude: longitude,
          UserTableColumns.createdAt: DateTime.now().toUtc().toIso8601String(),
          UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
        };

        final inserted = await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .insert(newUserData)
              .select()
              .single();
        });

        // Daftarkan juga akun ke Supabase Auth agar email terdaftar untuk menerima email pemulihan via Supabase
        try {
          await _client.auth.signUp(
            email: cleanEmail,
            password: password,
            data: {
              'nama_lengkap': cleanName,
              'no_hp': cleanPhone,
              'alamat_lengkap': cleanAlamat,
              'latitude': latitude,
              'longitude': longitude,
            },
          );
        } catch (_) {}

        return UserModel.fromDatabase(inserted);
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Gagal menyimpan pendaftaran: ${e.message}');
        }
        rethrow;
      }
    }

    // Fallback simulasi
    await Future.delayed(const Duration(milliseconds: 600));
    return UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      alamatLengkap: cleanAlamat,
      latitude: latitude,
      longitude: longitude,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
    );
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    if (_isSupabaseAvailable) {
      try {
        // Jika sudah ada sesi aktif dari provider Google di Supabase Auth, langsung sinkronkan
        final currentUser = _client.auth.currentUser;
        if (currentUser != null &&
            currentUser.appMetadata['provider'] == 'google') {
          return await _syncGoogleUserToDatabase(currentUser);
        }

        // Siapkan listener respons autentikasi OAuth callback
        final completer = Completer<UserModel>();
        StreamSubscription<AuthState>? authSubscription;

        authSubscription = _client.auth.onAuthStateChange.listen((data) async {
          final event = data.event;
          final session = data.session;
          if ((event == AuthChangeEvent.signedIn ||
                  event == AuthChangeEvent.tokenRefreshed ||
                  event == AuthChangeEvent.userUpdated) &&
              session != null) {
            try {
              final userModel = await _syncGoogleUserToDatabase(session.user);
              if (!completer.isCompleted) {
                completer.complete(userModel);
              }
            } catch (e) {
              if (!completer.isCompleted) {
                completer.completeError(e);
              }
            }
          }
        });

        // Buka halaman autentikasi Google OAuth Supabase
        final launched = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.satset://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );

        if (!launched) {
          await authSubscription.cancel();
          throw Exception('Gagal membuka halaman autentikasi Google.');
        }

        // Tunggu penyelesaian login dari browser dengan batas waktu 3 menit
        final userModel = await completer.future.timeout(
          const Duration(minutes: 3),
          onTimeout: () {
            throw Exception(
              'Waktu masuk dengan Google telah habis. Silakan coba lagi.',
            );
          },
        );

        await authSubscription.cancel();
        return userModel;
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Kesalahan basis data Supabase: ${e.message}');
        } else if (e is AuthException) {
          throw Exception('Autentikasi Google gagal: ${e.message}');
        }
        rethrow;
      }
    }

    // Fallback simulasi jika di lingkungan testing / tanpa koneksi Supabase
    await Future.delayed(const Duration(milliseconds: 600));
    final testGid = 'gid_google_${DateTime.now().millisecondsSinceEpoch}';
    return UserModel(
      id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Google User',
      email: 'user.satset@gmail.com',
      phone: '+6289876543210',
      googleId: testGid,
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      token: 'jwt_google_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
    );
  }

  /// Sinkronisasi profil pengguna Google ke tabel public.m_users berdasarkan google_id atau email
  Future<UserModel> _syncGoogleUserToDatabase(User supabaseUser) async {
    final cleanEmail = (supabaseUser.email ?? '').trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Gagal mendapatkan informasi email dari akun Google.');
    }

    // 1. Ekstrak Google ID dari identities akun atau userMetadata
    String googleId = '';
    final identities = supabaseUser.identities;
    if (identities != null && identities.isNotEmpty) {
      for (final identity in identities) {
        if (identity.provider.toLowerCase() == 'google') {
          googleId = identity.id;
          break;
        }
      }
    }
    if (googleId.isEmpty) {
      googleId = supabaseUser.userMetadata?['sub']?.toString() ??
          supabaseUser.userMetadata?['provider_id']?.toString() ??
          supabaseUser.id;
    }

    // 2. Ekstrak data profil (nama lengkap dan foto profil)
    final rawName = supabaseUser.userMetadata?['full_name'] as String? ??
        supabaseUser.userMetadata?['name'] as String? ??
        supabaseUser.userMetadata?['user_name'] as String?;
    final cleanName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : cleanEmail.split('@').first;

    final photoUrl = supabaseUser.userMetadata?['avatar_url'] as String? ??
        supabaseUser.userMetadata?['picture'] as String?;

    // 3. Cari di tabel public.m_users berdasarkan google_id
    final userByGoogleId = await _client
        .from(DatabaseConstants.tableUsers)
        .select()
        .eq(UserTableColumns.googleId, googleId)
        .maybeSingle();

    if (userByGoogleId != null) {
      // Pengguna sudah terdaftar & terhubung via google_id
      return UserModel.fromDatabase(userByGoogleId).copyWith(
        photoUrl: photoUrl ?? userByGoogleId['photo_url'] as String?,
      );
    }

    // 4. Jika belum ada google_id, cari berdasarkan email
    final userByEmail = await _client
        .from(DatabaseConstants.tableUsers)
        .select()
        .eq(UserTableColumns.email, cleanEmail)
        .maybeSingle();

    if (userByEmail != null) {
      // Pengguna sudah terdaftar manual sebelumnya, tautkan google_id ke akun tersebut
      final updated = await _client
          .from(DatabaseConstants.tableUsers)
          .update({
            UserTableColumns.googleId: googleId,
            UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
          })
          .eq(UserTableColumns.email, cleanEmail)
          .select()
          .single();

      return UserModel.fromDatabase(updated).copyWith(
        photoUrl: photoUrl ?? updated['photo_url'] as String?,
      );
    }

    // 5. Pengguna baru: Simpan baris data baru ke tabel public.m_users
    final newUserData = <String, dynamic>{
      UserTableColumns.namaLengkap: cleanName,
      UserTableColumns.email: cleanEmail,
      UserTableColumns.noHp: '',
      UserTableColumns.password: PasswordHasher.hash('GOOGLE_AUTH_$googleId'),
      UserTableColumns.googleId: googleId,
      UserTableColumns.createdAt: DateTime.now().toUtc().toIso8601String(),
      UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    final inserted = await _client
        .from(DatabaseConstants.tableUsers)
        .insert(newUserData)
        .select()
        .single();

    return UserModel.fromDatabase(inserted).copyWith(
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // Validasi format email menggunakan Validators
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    if (_isSupabaseAvailable) {
      try {
        // 1. Cek apakah email terdaftar di tabel m_users
        final user = await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .select(UserTableColumns.id)
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        });

        if (user == null) {
          throw Exception('Email tidak terdaftar pada akun SatSet.');
        }

        // 2. Hasilkan kode OTP 6 digit acak & waktu kedaluwarsa 3 menit
        final otpCode = OtpGenerator.generate6DigitCode();
        final expiration = OtpGenerator.getExpirationTime(minutes: 3);

        // 3. Simpan reset_token & token_expired_at ke tabel m_users
        await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .update({
                UserTableColumns.resetToken: otpCode,
                UserTableColumns.tokenExpiredAt: expiration.toIso8601String(),
                UserTableColumns.updatedAt: DateTime.now()
                    .toUtc()
                    .toIso8601String(),
              })
              .eq(UserTableColumns.email, cleanEmail);
        });

        // 4. Kirim email pemulihan via Supabase Auth
        try {
          await _client.auth.resetPasswordForEmail(cleanEmail);
        } catch (_) {
          try {
            await _client.auth.signInWithOtp(
              email: cleanEmail,
              shouldCreateUser: true,
            );
          } catch (_) {}
        }

        return;
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Gagal mengirim permintaan reset: ${e.message}');
        }
        rethrow;
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = code.trim();

    // Validasi email dan kode verifikasi menggunakan Validators
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final codeError = Validators.validateOtpCode(cleanCode);
    if (codeError != null) throw Exception(codeError);

    if (_isSupabaseAvailable) {
      try {
        bool isVerified = false;

        // 1. Coba verifikasi kode unik via Supabase Auth (Recovery OTP - dari resetPasswordForEmail)
        try {
          final res = await _client.auth.verifyOTP(
            email: cleanEmail,
            token: cleanCode,
            type: OtpType.recovery,
          );
          if (res.session != null || res.user != null) {
            isVerified = true;
          }
        } catch (_) {}

        // 2. Coba verifikasi kode via Supabase Auth (Email OTP - dari signInWithOtp)
        if (!isVerified) {
          try {
            final res = await _client.auth.verifyOTP(
              email: cleanEmail,
              token: cleanCode,
              type: OtpType.email,
            );
            if (res.session != null || res.user != null) {
              isVerified = true;
            }
          } catch (_) {}
        }

        // 3. Verifikasi dengan kode reset_token yang tersimpan di tabel m_users
        if (!isVerified) {
          final user = await _executeWithSessionRecovery(() async {
            return await _client
                .from(DatabaseConstants.tableUsers)
                .select()
                .eq(UserTableColumns.email, cleanEmail)
                .maybeSingle();
          });

          if (user == null) {
            throw Exception('Akun dengan email ini tidak ditemukan.');
          }

          final storedToken = user[UserTableColumns.resetToken]?.toString();
          if (storedToken == cleanCode) {
            final expiredAtRaw = user[UserTableColumns.tokenExpiredAt];
            if (expiredAtRaw != null) {
              final expiredAt = DateTime.tryParse(expiredAtRaw.toString());
              if (OtpGenerator.isExpired(expiredAt)) {
                throw Exception(
                  'Kode verifikasi telah kedaluwarsa. Silakan minta kode baru.',
                );
              }
            }
            isVerified = true;
          }
        }

        if (!isVerified) {
          throw Exception(
            'Kode verifikasi yang Anda masukkan salah atau telah kedaluwarsa.',
          );
        }

        return;
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Gagal memverifikasi kode: ${e.message}');
        }
        rethrow;
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (cleanCode == '000000') {
      throw Exception('Kode verifikasi salah atau telah kedaluwarsa.');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = code.trim();

    // Validasi input pembaruan kata sandi menggunakan Validators
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final codeError = Validators.validateOtpCode(cleanCode);
    if (codeError != null) throw Exception(codeError);

    final passwordError = Validators.validatePassword(newPassword);
    if (passwordError != null) throw Exception(passwordError);

    if (_isSupabaseAvailable) {
      try {
        // 1. Update kata sandi pengguna di Supabase Auth (jika ada sesi aktif)
        try {
          await _client.auth.updateUser(UserAttributes(password: newPassword));
        } catch (_) {}

        // 2. Hash kata sandi baru untuk disimpan di basis data m_users
        final hashedPassword = PasswordHasher.hash(newPassword);

        // 3. Update kata sandi baru dan bersihkan reset_token di tabel m_users
        await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .update({
                UserTableColumns.password: hashedPassword,
                UserTableColumns.resetToken: null,
                UserTableColumns.tokenExpiredAt: null,
                UserTableColumns.updatedAt: DateTime.now()
                    .toUtc()
                    .toIso8601String(),
              })
              .eq(UserTableColumns.email, cleanEmail);
        });

        return;
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('Gagal memperbarui kata sandi: ${e.message}');
        }
        rethrow;
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> resendVerificationCode(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    await forgotPassword(cleanEmail);
  }

  @override
  Future<void> logout() async {
    if (_isSupabaseAvailable) {
      try {
        await _client.auth.signOut();
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
