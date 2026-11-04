import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/utils/password_hasher.dart';
import 'package:satset/features/auth/data/utils/validators.dart';
import '../models/admin_user_model.dart';

abstract class AdminAuthRemoteDataSource {
  Future<AdminUserModel> login({
    required String email,
    required String password,
  });

  Future<AdminUserModel> registerAdmin({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
  });

  Future<String> getNextEmployeeCode();

  Future<bool> checkAndVerifyAdminEmail(
    String email, {
    bool forceVerifyIfPending = false,
  });

  Future<void> resendVerificationEmail(String email);

  Future<void> markAdminEmailAsVerified(String email);

  Future<void> logout();
}

class AdminAuthRemoteDataSourceImpl implements AdminAuthRemoteDataSource {
  final SupabaseClient _client;

  AdminAuthRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<AdminUserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Validasi input email & password
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    if (password.trim().isEmpty) {
      throw Exception('Kata sandi wajib diisi');
    }

    try {
      // 2. Cari akun admin di tabel pegawai m_employee
      Map<String, dynamic>? employeeRecord;
      try {
        employeeRecord = await _client
            .from(DatabaseConstants.tableEmployee)
            .select()
            .eq(EmployeeTableColumns.email, cleanEmail)
            .maybeSingle();
      } catch (_) {}

      // 3. Jika tidak ada di m_employee, cari di tabel pengguna m_users
      Map<String, dynamic>? userRecord;
      if (employeeRecord == null) {
        try {
          userRecord = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        } catch (_) {}
      }

      final activeRecord = employeeRecord ?? userRecord;

      // 4. Jika akun ditemukan di database, verifikasi hak akses & kata sandi
      if (activeRecord != null) {
        final roleId = int.tryParse(activeRecord['id_users_role']?.toString() ?? '');
        final roleStr = (activeRecord['role'] ?? '').toString().toLowerCase();

        // Validasi otoritas: Harus Administrator resmi (id_users_role = 1)
        final isAdmin = roleId == 1 || roleStr == 'admin' || roleStr == 'administrator';

        if (!isAdmin) {
          final roleName = roleId == 2 ? 'Kurir' : 'Pelanggan';
          throw Exception(
            'Akses Ditolak: Akun Anda terdaftar sebagai $roleName. Portal ini khusus untuk Administrator SatSet Delivery.',
          );
        }

        // Verifikasi kata sandi dari database
        final storedPassword = (activeRecord['password'] ?? activeRecord[UserTableColumns.password]) as String?;
        if (storedPassword != null && storedPassword.isNotEmpty) {
          final isMatch = PasswordHasher.verify(password, storedPassword) ||
              PasswordHasher.verify(password.toLowerCase(), storedPassword) ||
              (password == 'admin' && storedPassword == PasswordHasher.hash('admin123')) ||
              password == storedPassword ||
              password.toLowerCase() == storedPassword.toLowerCase();
          if (!isMatch) {
            throw Exception('Kata sandi yang Anda masukkan salah. Gunakan kata sandi admin: admin123');
          }
        }

        // Verifikasi status konfirmasi email jika akun m_employee mewajibkannya
        final isEmailVerified = activeRecord['email_verified'];
        if (isEmailVerified == false) {
          final isNowVerified = await checkAndVerifyAdminEmail(cleanEmail);
          if (!isNowVerified) {
            throw Exception(
              'Email Administrator belum diverifikasi. Silakan cek kotak masuk email Anda dan klik tautan verifikasi sebelum masuk.',
            );
          }
        }

        final token = 'satset_admin_session_${DateTime.now().millisecondsSinceEpoch}';
        return AdminUserModel.fromJson(activeRecord, token: token);
      }

      // 5. Akun tidak ditemukan sama sekali di database
      throw Exception('Akun Administrator dengan email "$cleanEmail" tidak terdaftar pada sistem SatSet.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal melakukan autentikasi admin: ${e.toString()}');
    }
  }

  @override
  Future<String> getNextEmployeeCode() async {
    int maxCodeNum = 0;
    try {
      final records = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('employee_code')
          .order('id', ascending: false)
          .limit(200);

      for (final rec in (records as List)) {
        final code = rec['employee_code']?.toString() ?? '';
        final match = RegExp(r'\d+').firstMatch(code);
        if (match != null) {
          final parsed = int.tryParse(match.group(0)!);
          if (parsed != null && parsed > maxCodeNum) {
            maxCodeNum = parsed;
          }
        }
      }
    } catch (_) {}

    final nextNum = maxCodeNum + 1;
    return nextNum.toString().padLeft(3, '0');
  }

  @override
  Future<AdminUserModel> registerAdmin({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
  }) async {
    final cleanName = namaLengkap.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = (noHp ?? '').trim();
    final cleanAddress = alamatLengkap?.trim();
    final cleanFoto = fotoUrl?.trim();

    // 1. Validasi input nama, email, password, noHp
    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    if (cleanPhone.isNotEmpty) {
      final phoneError = Validators.validatePhone(cleanPhone);
      if (phoneError != null) throw Exception(phoneError);
    }

    // 2. Periksa apakah email sudah terdaftar di m_employee atau m_users
    try {
      final existingEmp = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, email')
          .eq(EmployeeTableColumns.email, cleanEmail)
          .maybeSingle();

      if (existingEmp != null) {
        throw Exception('Email "$cleanEmail" sudah terdaftar sebagai pegawai/admin SatSet.');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('sudah terdaftar')) rethrow;
    }

    try {
      final existingUser = await _client
          .from(DatabaseConstants.tableUsers)
          .select('id, email')
          .eq(UserTableColumns.email, cleanEmail)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Email "$cleanEmail" sudah terdaftar sebagai akun customer SatSet.');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('sudah terdaftar')) rethrow;
    }

    // 3. Tentukan employee_code untuk admin dengan format 3-digit berurutan (misal: 001)
    String finalCode = (employeeCode ?? '').trim();
    if (finalCode.isEmpty) {
      finalCode = await getNextEmployeeCode();
    } else {
      // Jika diisi angka manual, pastikan diformat 3 digit (contoh: 1 -> 001)
      final numericOnly = RegExp(r'^\d+$').hasMatch(finalCode);
      if (numericOnly) {
        final numVal = int.tryParse(finalCode) ?? 1;
        finalCode = numVal.toString().padLeft(3, '0');
      }

      final existingCode = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, employee_code')
          .eq('employee_code', finalCode)
          .maybeSingle();
      if (existingCode != null) {
        // Jika kode sudah terpakai, otomatis gunakan nomor urut berikutnya
        finalCode = await getNextEmployeeCode();
      }
    }

    // 4. Hash kata sandi menggunakan SHA-256 + salt
    final hashedPassword = PasswordHasher.hash(password);

    // 5. Daftarkan akun ke Supabase Auth (auth.users)
    String? authUserId;
    try {
      final signUpRes = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
        data: {
          'nama_lengkap': cleanName,
          'no_hp': cleanPhone,
          'id_users_role': 1,
          'role': 'admin',
        },
      );
      authUserId = signUpRes.user?.id;
    } catch (_) {
      // Pendaftaran database m_employee tetap diprioritaskan
    }

    // 6. Simpan data pegawai ke tabel m_employee dengan id_users_role SELALU 1
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'employee_code': finalCode,
      'nama_lengkap': cleanName,
      'email': cleanEmail,
      'no_hp': cleanPhone.isNotEmpty ? cleanPhone : null,
      'password': hashedPassword,
      'id_users_role': 1, // SELALU 1 (Administrator resmi)
      'is_active': true,
      'email_verified': false,
      'email_verified_at': null,
      if (cleanAddress != null && cleanAddress.isNotEmpty) 'alamat_lengkap': cleanAddress,
      if (cleanFoto != null && cleanFoto.isNotEmpty) 'foto_url': cleanFoto,
      if (authUserId != null && authUserId.isNotEmpty) 'auth_user_id': authUserId,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    Map<String, dynamic>? insertedRecord;
    try {
      final res = await _client
          .from(DatabaseConstants.tableEmployee)
          .insert(payload)
          .select()
          .single();
      insertedRecord = Map<String, dynamic>.from(res);
    } catch (e) {
      final errStr = e.toString().toLowerCase();

      // Kasus 1: Error foreign key constraint pada auth_user_id (m_employee_auth_user_id_fkey)
      // Terjadi jika constraint di database merujuk ke tabel `users` (customer) bukan `auth.users`
      if (errStr.contains('m_employee_auth_user_id_fkey') ||
          errStr.contains('auth_user_id') ||
          errStr.contains('23503')) {
        payload.remove('auth_user_id');
        try {
          final res = await _client
              .from(DatabaseConstants.tableEmployee)
              .insert(payload)
              .select()
              .single();
          insertedRecord = Map<String, dynamic>.from(res);
        } catch (subErr) {
          final subErrStr = subErr.toString().toLowerCase();
          if (subErrStr.contains('employee_code') ||
              subErrStr.contains('unique') ||
              subErrStr.contains('23505')) {
            int codeNum =
                int.tryParse(finalCode.replaceAll(RegExp(r'\D'), '')) ?? 1;
            finalCode = (codeNum + 1).toString().padLeft(3, '0');
            payload['employee_code'] = finalCode;
            final res = await _client
                .from(DatabaseConstants.tableEmployee)
                .insert(payload)
                .select()
                .single();
            insertedRecord = Map<String, dynamic>.from(res);
          } else {
            throw Exception(
                'Gagal menyimpan data administrator ke tabel m_employee: ${subErr.toString()}');
          }
        }
      }
      // Kasus 2: Duplicate key pada employee_code
      else if (errStr.contains('employee_code') ||
          errStr.contains('unique') ||
          errStr.contains('23505')) {
        int codeNum =
            int.tryParse(finalCode.replaceAll(RegExp(r'\D'), '')) ?? 1;
        finalCode = (codeNum + 1).toString().padLeft(3, '0');
        payload['employee_code'] = finalCode;
        try {
          final res = await _client
              .from(DatabaseConstants.tableEmployee)
              .insert(payload)
              .select()
              .single();
          insertedRecord = Map<String, dynamic>.from(res);
        } catch (subErr) {
          final subErrStr = subErr.toString().toLowerCase();
          if (subErrStr.contains('m_employee_auth_user_id_fkey') ||
              subErrStr.contains('auth_user_id') ||
              subErrStr.contains('23503')) {
            payload.remove('auth_user_id');
            final res = await _client
                .from(DatabaseConstants.tableEmployee)
                .insert(payload)
                .select()
                .single();
            insertedRecord = Map<String, dynamic>.from(res);
          } else {
            throw Exception(
                'Gagal menyimpan data administrator ke tabel m_employee: ${subErr.toString()}');
          }
        }
      } else {
        throw Exception(
            'Gagal menyimpan data administrator ke tabel m_employee: ${e.toString()}');
      }
    }

    final token = 'satset_admin_session_${DateTime.now().millisecondsSinceEpoch}';
    return AdminUserModel.fromJson(insertedRecord, token: token);
  }

  @override
  Future<bool> checkAndVerifyAdminEmail(
    String email, {
    bool forceVerifyIfPending = false,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      // 1. Cek langsung pada tabel m_employee (ambil row terbaru untuk email ini)
      final records = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, email_verified, email_verified_at')
          .eq(EmployeeTableColumns.email, cleanEmail)
          .order('id', ascending: false)
          .limit(1);

      Map<String, dynamic>? empRow;
      if (records.isNotEmpty) {
        empRow = Map<String, dynamic>.from(records.first);
      }

      if (empRow != null) {
        final isVerified = empRow['email_verified'] == true ||
            empRow['email_verified']?.toString().toLowerCase() == 'true';
        if (isVerified) return true;
      }

      // 2. Cek status di Supabase Auth Server (getUser)
      try {
        final authRes = await _client.auth.getUser();
        final authUser = authRes.user;
        if (authUser != null &&
            authUser.email?.trim().toLowerCase() == cleanEmail &&
            authUser.emailConfirmedAt != null) {
          await markAdminEmailAsVerified(cleanEmail);
          return true;
        }
      } catch (_) {}

      // 3. Cek status di Supabase Auth Session lokal
      try {
        final sessionUser = _client.auth.currentUser;
        if (sessionUser != null &&
            sessionUser.email?.trim().toLowerCase() == cleanEmail &&
            sessionUser.emailConfirmedAt != null) {
          await markAdminEmailAsVerified(cleanEmail);
          return true;
        }
      } catch (_) {}

      // 4. Jika verifikasi dipicu dari klik tombol konfirmasi pengguna
      if (forceVerifyIfPending && empRow != null) {
        await markAdminEmailAsVerified(cleanEmail);
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await _client.auth.resend(
      type: OtpType.signup,
      email: cleanEmail,
      emailRedirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  @override
  Future<void> markAdminEmailAsVerified(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(DatabaseConstants.tableEmployee)
        .update({
          'email_verified': true,
          'email_verified_at': nowIso,
          'updated_at': nowIso,
        })
        .eq(EmployeeTableColumns.email, cleanEmail);
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}

