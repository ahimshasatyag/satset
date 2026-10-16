import '../entities/user.dart';

/// Interface kontrak repository untuk proses autentikasi aplikasi SatSet
abstract class AuthRepository {
  /// Proses login dengan email dan kata sandi
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Proses registrasi akun pengguna baru
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Proses login cepat menggunakan akun Google
  Future<User> loginWithGoogle();

  /// Mengambil data user yang sedang login dari sesi lokal
  Future<User?> getCurrentUser();

  /// Keluar dari sesi login (logout)
  Future<void> logout();

  /// Mengirim permintaan reset kata sandi ke email
  Future<void> forgotPassword(String email);

  /// Memeriksa status opsi "Ingat Saya" (Remember Me)
  Future<bool> isRememberMe();
}
