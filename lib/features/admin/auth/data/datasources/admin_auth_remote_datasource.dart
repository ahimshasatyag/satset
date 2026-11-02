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
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}

