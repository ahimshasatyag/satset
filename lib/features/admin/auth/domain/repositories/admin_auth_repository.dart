import '../entities/admin_user.dart';

/// Kontrak repository untuk autentikasi Administrator SatSet
abstract class AdminAuthRepository {
  /// Melakukan login administrator dengan email dan password
  Future<AdminUser> login({required String email, required String password});

  /// Mendaftarkan administrator baru ke database m_employee dengan id_users_role = 1
  Future<AdminUser> registerAdmin({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
  });

  /// Mengambil kode pegawai berikutnya dalam format 001
  Future<String> getNextEmployeeCode();

  /// Memeriksa apakah email administrator telah terkonfirmasi
  Future<bool> checkAndVerifyAdminEmail(
    String email, {
    bool forceVerifyIfPending = false,
  });

  /// Mengirim ulang email tautan konfirmasi
  Future<void> resendVerificationEmail(String email);

  /// Menandai email administrator sebagai terverifikasi pada m_employee
  Future<void> markAdminEmailAsVerified(String email);

  /// Mengambil data administrator yang sedang aktif login di sesi lokal
  Future<AdminUser?> getCurrentAdmin();

  /// Melakukan logout dan membersihkan sesi lokal
  Future<void> logout();

  /// Menyimpan kredensial email jika "Ingat Saya" dicentang
  Future<void> saveRememberMe({required String email, required bool remember});

  /// Mengambil status "Ingat Saya" dan email tersimpan
  Future<Map<String, dynamic>> getRememberMe();
}
