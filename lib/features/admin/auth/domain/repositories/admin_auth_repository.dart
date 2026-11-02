import '../entities/admin_user.dart';

/// Kontrak repository untuk autentikasi Administrator SatSet
abstract class AdminAuthRepository {
  /// Melakukan login administrator dengan email dan password
  Future<AdminUser> login({
    required String email,
    required String password,
  });

  /// Mengambil data administrator yang sedang aktif login di sesi lokal
  Future<AdminUser?> getCurrentAdmin();

  /// Melakukan logout dan membersihkan sesi lokal
  Future<void> logout();

  /// Menyimpan kredensial email jika "Ingat Saya" dicentang
  Future<void> saveRememberMe({required String email, required bool remember});

  /// Mengambil status "Ingat Saya" dan email tersimpan
  Future<Map<String, dynamic>> getRememberMe();
}

