import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitas enkripsi dan verifikasi kata sandi akun SatSet menggunakan hashing SHA-256
class PasswordHasher {
  PasswordHasher._();

  static const String _appSalt = 'satset_secure_salt_2026_';

  /// Menghasilkan hash SHA-256 dari teks kata sandi dengan salt
  static String hash(String password) {
    final saltedPassword = '$_appSalt$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Memverifikasi apakah kata sandi mentah cocok dengan hash tersimpan di basis data
  static bool verify(String rawPassword, String hashedPassword) {
    final computedHash = hash(rawPassword);
    return computedHash == hashedPassword;
  }
}
