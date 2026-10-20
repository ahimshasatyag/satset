/// Kumpulan validator form untuk fitur autentikasi (Login, Register, Reset Password, OTP)
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');

  static final RegExp _phoneRegex =
      RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,11}$');

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
