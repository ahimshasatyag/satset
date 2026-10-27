import 'package:google_sign_in/google_sign_in.dart';
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
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
  });

  Future<UserModel> registerCourier({
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

  void _ensureSupabaseAvailable() {
    if (!_isSupabaseAvailable) {
      throw Exception(
        'Layanan Supabase tidak tersedia. Periksa koneksi jaringan Anda.',
      );
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

    _ensureSupabaseAvailable();
    try {
      // 1. Cek di tabel master pengguna m_users
      Map<String, dynamic>? response = await _executeWithSessionRecovery(
        () async {
          return await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        },
      );

      bool isFromEmployeeTable = false;

      // 2. Jika tidak ditemukan di m_users, cek di tabel master pegawai / kurir m_employee
      if (response == null) {
        try {
          response = await _executeWithSessionRecovery(() async {
            return await _client
                .from(DatabaseConstants.tableEmployee)
                .select()
                .eq(EmployeeTableColumns.email, cleanEmail)
                .maybeSingle();
          });
          if (response != null) {
            isFromEmployeeTable = true;
          }
        } catch (_) {
          // Abaikan jika tabel m_employee belum ada atau terjadi error
        }
      }

      if (response == null) {
        throw Exception('Email belum terdaftar pada sistem SatSet.');
      }

      final storedHashedPassword =
          (response[UserTableColumns.password] ?? response['password'])
              as String?;
      if (storedHashedPassword != null && storedHashedPassword.isNotEmpty) {
        final isPasswordValid = PasswordHasher.verify(
          password,
          storedHashedPassword,
        );
        if (!isPasswordValid) {
          throw Exception('Kata sandi yang Anda masukkan salah.');
        }
      }

      // 3. Tentukan id_users_role (2 = Courier, 3 = Customer)
      int? idUsersRole;
      if (response['id_users_role'] != null) {
        idUsersRole = int.tryParse(response['id_users_role'].toString());
      }

      if (isFromEmployeeTable) {
        idUsersRole ??= 2;
      } else if (idUsersRole == null) {
        // Jika ditemukan di m_users tanpa id_users_role, periksa apakah terdaftar di m_employee
        try {
          final userId = response[UserTableColumns.id];
          final employeeData = await _client
              .from(DatabaseConstants.tableEmployee)
              .select()
              .or('email.eq.$cleanEmail,user_id.eq.$userId')
              .maybeSingle();

          if (employeeData != null) {
            idUsersRole =
                int.tryParse(
                  employeeData['id_users_role']?.toString() ?? '2',
                ) ??
                2;
          }
        } catch (_) {}
      }

      // Fallback berdasarkan nama role jika id_users_role belum terisi
      if (idUsersRole == null) {
        final roleString = response['role']?.toString().toLowerCase();
        if (roleString == 'courier' || roleString == 'kurir') {
          idUsersRole = 2;
        } else {
          idUsersRole = 3;
        }
      }

      // Terapkan penyesuaian role ke payload
      response['id_users_role'] = idUsersRole;
      if (idUsersRole == 2) {
        response['role'] = 'courier';
      } else if (idUsersRole == 3) {
        response['role'] = 'customer';
      }

      // 4. Perbarui lokasi pengguna terkini di database Supabase jika koordinat tersedia
      if (latitude != null && longitude != null) {
        try {
          final targetTable = isFromEmployeeTable
              ? DatabaseConstants.tableEmployee
              : DatabaseConstants.tableUsers;
          await _client
              .from(targetTable)
              .update({
                'latitude': latitude,
                'longitude': longitude,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', response['id']);

          response['latitude'] = latitude;
          response['longitude'] = longitude;
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

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
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

    _ensureSupabaseAvailable();
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
      final newUserData = <String, dynamic>{
        UserTableColumns.namaLengkap: cleanName,
        UserTableColumns.email: cleanEmail,
        UserTableColumns.noHp: cleanPhone,
        UserTableColumns.password: hashedPassword,
        UserTableColumns.alamatLengkap: cleanAlamat,
        UserTableColumns.latitude: latitude,
        UserTableColumns.longitude: longitude,
        UserTableColumns.emailVerified: false,
        UserTableColumns.emailVerifiedAt: null,
        if (idProvinsi != null && idProvinsi.trim().isNotEmpty)
          UserTableColumns.idProvinsi: idProvinsi.trim(),
        if (idKabkot != null && idKabkot.trim().isNotEmpty)
          UserTableColumns.idKabkot: idKabkot.trim(),
        if (idKecamatan != null && idKecamatan.trim().isNotEmpty)
          UserTableColumns.idKecamatan: idKecamatan.trim(),
        if (idKelurahan != null && idKelurahan.trim().isNotEmpty)
          UserTableColumns.idKelurahan: idKelurahan.trim(),
        UserTableColumns.createdAt: DateTime.now().toUtc().toIso8601String(),
        UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
      };

      Map<String, dynamic> inserted = {};
      bool insertSuccess = false;
      int maxRetries = 3;

      while (!insertSuccess && maxRetries > 0) {
        maxRetries--;
        try {
          inserted = await _executeWithSessionRecovery(() async {
            return await _client
                .from(DatabaseConstants.tableUsers)
                .insert(newUserData)
                .select()
                .single();
          });
          insertSuccess = true;
        } catch (e) {
          if (e is PostgrestException) {
            final match = RegExp(r"Could not find the '([^']+)' column")
                .firstMatch(e.message);
            if (match != null) {
              final missingCol = match.group(1);
              if (missingCol != null && newUserData.containsKey(missingCol)) {
                newUserData.remove(missingCol);
                continue;
              }
            }

            // Fallback toleransi jika kolom id_kelurahan pada schema database belum diubah menjadi varchar(13)
            // atau terdapat kendala foreign key constraint fk_users_kelurahan
            if (e.message.contains('fk_users_kelurahan') ||
                e.message.contains('id_kelurahan') ||
                (e.message.contains('value too long for type character varying') &&
                    e.message.contains('12'))) {
              if (newUserData.containsKey(UserTableColumns.idKelurahan)) {
                newUserData.remove(UserTableColumns.idKelurahan);
                continue;
              }
            }
          }
          rethrow;
        }
      }

      // Daftarkan juga akun ke Supabase Auth agar email terdaftar untuk menerima email konfirmasi via Supabase
      try {
        await _client.auth.signUp(
          email: cleanEmail,
          password: password,
          emailRedirectTo: 'io.supabase.satset://login-callback',
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

  @override
  Future<UserModel> registerCourier({
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

    // Validasi data pendaftaran kurir menggunakan Validators
    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final phoneError = Validators.validatePhone(cleanPhone);
    if (phoneError != null) throw Exception(phoneError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    _ensureSupabaseAvailable();
    try {
      // 1. Cek apakah email sudah terdaftar di tabel master pegawai / kurir m_employee
      final existingEmployee = await _executeWithSessionRecovery(() async {
        return await _client
            .from(DatabaseConstants.tableEmployee)
            .select(EmployeeTableColumns.id)
            .eq(EmployeeTableColumns.email, cleanEmail)
            .maybeSingle();
      });

      if (existingEmployee != null) {
        throw Exception(
          'Email kurir sudah terdaftar. Silakan masuk dengan akun Anda.',
        );
      }

      // Cek juga di tabel m_users untuk memastikan email tidak bertabrakan
      final existingUser = await _executeWithSessionRecovery(() async {
        return await _client
            .from(DatabaseConstants.tableUsers)
            .select(UserTableColumns.id)
            .eq(UserTableColumns.email, cleanEmail)
            .maybeSingle();
      });

      if (existingUser != null) {
        throw Exception(
          'Email sudah terdaftar pada sistem SatSet sebagai pelanggan.',
        );
      }

      // 2. Hash kata sandi untuk keamanan penyimpanan di basis data
      final hashedPassword = PasswordHasher.hash(password);

      // 3. Daftarkan juga akun ke Supabase Auth
      String? authUserId;
      try {
        final authRes = await _client.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'nama_lengkap': cleanName,
            'no_hp': cleanPhone,
            'alamat_lengkap': cleanAlamat,
            'role': 'courier',
            'id_users_role': 2,
          },
        );
        authUserId = authRes.user?.id;
      } catch (_) {}

      // 4. Buat kode kurir otomatis (employee_code) dengan format 001, 002, dst.
      String nextEmployeeCode = '001';
      int maxCodeNum = 0;
      try {
        final employees = await _executeWithSessionRecovery(() async {
          return await _client
              .from(DatabaseConstants.tableEmployee)
              .select('employee_code')
              .order('id', ascending: false)
              .limit(50);
        });

        if (employees.isNotEmpty) {
          for (final emp in employees) {
            final code = emp['employee_code']?.toString() ?? '';
            final match = RegExp(r'\d+').firstMatch(code);
            if (match != null) {
              final parsed = int.tryParse(match.group(0)!);
              if (parsed != null && parsed > maxCodeNum) {
                maxCodeNum = parsed;
              }
            }
          }
        }

        if (maxCodeNum == 0) {
          try {
            final countRes = await _client
                .from(DatabaseConstants.tableEmployee)
                .count(CountOption.exact);
            maxCodeNum = countRes;
          } catch (_) {}
        }

        nextEmployeeCode = (maxCodeNum + 1).toString().padLeft(3, '0');
      } catch (_) {
        nextEmployeeCode = '001';
      }

      // 5. Simpan data kurir ke tabel m_employee di Supabase
      // Menyertakan employee_code dengan format 001 dst untuk memenuhi not-null constraint
      final newEmployeeData = <String, dynamic>{
        'employee_code': nextEmployeeCode,
        'email': cleanEmail,
        'nama_lengkap': cleanName,
        'no_hp': cleanPhone,
        'password': hashedPassword,
        'id_users_role': 2,
        if (cleanAlamat != null && cleanAlamat.isNotEmpty)
          'alamat_lengkap': cleanAlamat,
        'user_id': ?authUserId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      Map<String, dynamic> inserted = {};
      bool insertSuccess = false;
      int maxRetries = 6;
      int currentCodeNum = int.tryParse(nextEmployeeCode) ?? 1;

      while (!insertSuccess && maxRetries > 0) {
        maxRetries--;
        try {
          inserted = await _executeWithSessionRecovery(() async {
            return await _client
                .from(DatabaseConstants.tableEmployee)
                .insert(newEmployeeData)
                .select()
                .single();
          });
          insertSuccess = true;
        } catch (e) {
          if (e is PostgrestException) {
            // Jika terjadi konflik duplikasi kode kurir, naikkan angka berikutnya (002, 003, dst)
            if (e.message.toLowerCase().contains('unique') ||
                e.message.toLowerCase().contains('duplicate') ||
                e.code == '23505') {
              currentCodeNum++;
              newEmployeeData['employee_code'] = currentCodeNum
                  .toString()
                  .padLeft(3, '0');
              continue;
            }

            final match = RegExp(r"Could not find the '([^']+)' column")
                .firstMatch(e.message);
            if (match != null) {
              final missingCol = match.group(1);
              if (missingCol != null &&
                  newEmployeeData.containsKey(missingCol)) {
                newEmployeeData.remove(missingCol);
                continue;
              }
            }
          }
          rethrow;
        }
      }

      // Pastikan atribut id_users_role = 2 dan role = courier terpasang
      inserted['email'] ??= cleanEmail;
      inserted['nama_lengkap'] ??= cleanName;
      inserted['no_hp'] ??= cleanPhone;
      inserted['id_users_role'] = 2;
      inserted['role'] = 'courier';

      return UserModel.fromDatabase(inserted);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Gagal menyimpan pendaftaran kurir: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    _ensureSupabaseAvailable();

    try {
      // 1. Selalu bersihkan sesi aktif sebelumnya agar tidak langsung otomatis masuk
      try {
        await _client.auth.signOut();
      } catch (_) {}

      // Web Client ID resmi Google Cloud Console
      const webClientId =
          '26653678785-i2mp4755sb45hg4eiqnac6h4bb3q98hs.apps.googleusercontent.com';

      // 2. Coba autentikasi Native Google Sign-In (modal Android Play Services tanpa browser Chrome)
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
        );
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;

          if (idToken != null) {
            final authResponse = await _client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            final user = authResponse.user;
            if (user != null) {
              return await _syncGoogleUserToDatabase(user);
            }
          }
        } else {
          throw Exception('Masuk dengan Google dibatalkan.');
        }
      } catch (nativeError) {
        final errStr = nativeError.toString();
        if (errStr.toLowerCase().contains('dibatalkan') ||
            errStr.toLowerCase().contains('canceled')) {
          throw Exception('Masuk dengan Google dibatalkan.');
        }
        throw Exception(
          'Gagal masuk dengan Google: $nativeError. '
          'Jika baru menambahkan plugin Google Sign-In, hentikan terminal lalu jalankan ulang "flutter run".',
        );
      }
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Kesalahan basis data Supabase: ${e.message}');
      } else if (e is AuthException) {
        throw Exception('Autentikasi Google gagal: ${e.message}');
      }
      rethrow;
    }
    throw Exception('Gagal menyelesaikan proses autentikasi Google.');
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
      googleId =
          supabaseUser.userMetadata?['sub']?.toString() ??
          supabaseUser.userMetadata?['provider_id']?.toString() ??
          supabaseUser.id;
    }

    // 2. Ekstrak data profil (nama lengkap dan foto profil)
    final rawName =
        supabaseUser.userMetadata?['full_name'] as String? ??
        supabaseUser.userMetadata?['name'] as String? ??
        supabaseUser.userMetadata?['user_name'] as String?;
    final cleanName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : cleanEmail.split('@').first;

    final photoUrl =
        supabaseUser.userMetadata?['avatar_url'] as String? ??
        supabaseUser.userMetadata?['picture'] as String?;

    // 3. Cari di tabel public.m_users berdasarkan google_id
    final userByGoogleId = await _client
        .from(DatabaseConstants.tableUsers)
        .select()
        .eq(UserTableColumns.googleId, googleId)
        .maybeSingle();

    if (userByGoogleId != null) {
      // Pengguna sudah terdaftar & terhubung via google_id
      return UserModel.fromDatabase(
        userByGoogleId,
      ).copyWith(photoUrl: photoUrl ?? userByGoogleId['photo_url'] as String?);
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
            UserTableColumns.updatedAt: DateTime.now()
                .toUtc()
                .toIso8601String(),
          })
          .eq(UserTableColumns.email, cleanEmail)
          .select()
          .single();

      return UserModel.fromDatabase(updated)
          .copyWith(photoUrl: photoUrl ?? updated['photo_url'] as String?);
    }

    // 5. Pengguna baru: Simpan baris data baru ke tabel public.m_users
    final newUserData = <String, dynamic>{
      UserTableColumns.namaLengkap: cleanName,
      UserTableColumns.email: cleanEmail,
      UserTableColumns.noHp: '',
      UserTableColumns.password: PasswordHasher.hash('GOOGLE_AUTH_$googleId'),
      UserTableColumns.googleId: googleId,
      UserTableColumns.idUsersRole: 3,
      UserTableColumns.role: 'customer',
      UserTableColumns.createdAt: DateTime.now().toUtc().toIso8601String(),
      UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    final inserted = await _client
        .from(DatabaseConstants.tableUsers)
        .insert(newUserData)
        .select()
        .single();

    return UserModel.fromDatabase(inserted).copyWith(photoUrl: photoUrl);
  }

  @override
  Future<void> forgotPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // Validasi format email menggunakan Validators
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    _ensureSupabaseAvailable();
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

    _ensureSupabaseAvailable();
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

    _ensureSupabaseAvailable();
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

  @override
  Future<void> resendVerificationCode(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    await forgotPassword(cleanEmail);
  }

  @override
  Future<void> logout() async {
    _ensureSupabaseAvailable();
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
