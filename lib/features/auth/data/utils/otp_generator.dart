import 'dart:math';

/// Generator kode OTP unik dan durasi kedaluwarsa untuk fitur verifikasi & reset kata sandi email
class OtpGenerator {
  OtpGenerator._();

  static final Random _random = Random.secure();

  /// Menghasilkan 6 digit kode unik numerik acak (contoh: '482910')
  static String generate6DigitCode() {
    final codeNumber = _random.nextInt(900000) + 100000;
    return codeNumber.toString();
  }

  /// Menghasilkan timestamp waktu kedaluwarsa (default 3 menit dari sekarang)
  static DateTime getExpirationTime({int minutes = 3}) {
    return DateTime.now().toUtc().add(Duration(minutes: minutes));
  }

  /// Mengecek apakah token sudah kedaluwarsa
  static bool isExpired(DateTime? expiredAt) {
    if (expiredAt == null) return true;
    return DateTime.now().toUtc().isAfter(expiredAt);
  }
}
