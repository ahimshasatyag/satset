import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';

/// Status hasil pengecekan email di database
enum EmailCheckStatus {
  idle,
  checking,
  available,
  alreadyRegistered,
}

/// Model hasil pengecekan email di database
class EmailCheckResult {
  final EmailCheckStatus status;
  final bool isValid;
  final String? errorMessage;

  const EmailCheckResult({
    required this.status,
    required this.isValid,
    this.errorMessage,
  });

  factory EmailCheckResult.idle() => const EmailCheckResult(
        status: EmailCheckStatus.idle,
        isValid: true,
      );

  factory EmailCheckResult.checking() => const EmailCheckResult(
        status: EmailCheckStatus.checking,
        isValid: false,
      );

  factory EmailCheckResult.available() => const EmailCheckResult(
        status: EmailCheckStatus.available,
        isValid: true,
      );

  factory EmailCheckResult.alreadyRegistered() => const EmailCheckResult(
        status: EmailCheckStatus.alreadyRegistered,
        isValid: false,
        errorMessage: 'Email ini sudah terdaftar. Silakan login.',
      );
}

/// Kumpulan validator form untuk fitur autentikasi (Login, Register, Reset Password, OTP)
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');

  static final RegExp _phoneRegex =
      RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,11}$');

  static final RegExp _lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp _upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#\$&*~_.,\-]');

  /// Validasi nama lengkap akun
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    if (value.trim().length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    return null;
  }

  /// Validasi alamat email akun
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat email wajib diisi';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid (contoh: nama@satset.id)';
    }
    return null;
  }

  /// Memeriksa apakah email sudah terdaftar di database Supabase m_users
  static Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    try {
      final response = await SupabaseConfig.client
          .from(DatabaseConstants.tableUsers)
          .select(UserTableColumns.id)
          .eq(UserTableColumns.email, cleanEmail)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Pengecekan ketersediaan email di database (belum / sudah terdaftar)
  static Future<EmailCheckResult> checkEmailAvailability(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return EmailCheckResult.idle();
    }

    final isRegistered = await isEmailRegistered(cleanEmail);
    if (isRegistered) {
      return EmailCheckResult.alreadyRegistered();
    }

    return EmailCheckResult.available();
  }

  /// Validasi nomor HP akun
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP wajib diisi';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\s|-'), '');
    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return 'Nomor HP tidak valid (contoh: 081234567890)';
    }
    return null;
  }

  /// Validasi alamat lengkap minimal 5 karakter
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat lengkap wajib diisi';
    }
    if (value.trim().length < 5) {
      return 'Alamat minimal 5 karakter';
    }
    return null;
  }

  /// Validasi kata sandi minimal 8 karakter
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal harus 8 karakter';
    }
    return null;
  }

  /// Validasi konfirmasi kata sandi harus sama dengan kata sandi
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != password) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }

  // ===== Kriteria kekuatan kata sandi =====

  /// Minimal 8 karakter
  static bool hasMinLength(String password) => password.length >= 8;

  /// Kombinasi huruf besar & kecil
  static bool hasMixedCase(String password) =>
      _lowerCaseRegex.hasMatch(password) && _upperCaseRegex.hasMatch(password);

  /// Mengandung angka
  static bool hasDigit(String password) => _digitRegex.hasMatch(password);

  /// Mengandung simbol / karakter khusus
  static bool hasSpecialChar(String password) =>
      _specialCharRegex.hasMatch(password);

  /// Validasi kode unik OTP 6 digit
  static String? validateOtpCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode verifikasi wajib diisi';
    }
    if (value.trim().length != 6) {
      return 'Kode verifikasi harus 6 digit';
    }
    return null;
  }
}

/// Alias untuk kompatibilitas penamaan AuthValidators
typedef AuthValidators = Validators;
