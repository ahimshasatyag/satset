import '../entities/user.dart';

/// Interface kontrak repository untuk proses autentikasi aplikasi SatSet
abstract class AuthRepository {
  /// Proses login dengan email dan kata sandi
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
    double? latitude,
    double? longitude,
  });

  /// Proses registrasi akun pengguna baru (Pelanggan)
  Future<User> register({
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

  /// Proses registrasi akun khusus kurir (ke tabel m_employee dengan id_users_role=2)
  Future<User> registerCourier({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
  });

  /// Proses login cepat menggunakan akun Google
  Future<User> loginWithGoogle();

  /// Mengambil data user yang sedang login dari sesi lokal
  Future<User?> getCurrentUser();

  /// Keluar dari sesi login (logout)
  Future<void> logout();

  /// Mengirim permintaan reset kata sandi ke email
  Future<void> forgotPassword(String email);

  /// Memverifikasi kode unik (OTP) yang dikirim ke email
  Future<void> verifyResetCode({
    required String email,
    required String code,
  });

  /// Menyimpan kata sandi baru pengguna
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Mengirim ulang kode verifikasi unik ke email
  Future<void> resendVerificationCode(String email);

  /// Memeriksa status opsi "Ingat Saya" (Remember Me)
  Future<bool> isRememberMe();
}
