/// Utility formatter standar untuk nominal angka dan mata uang Rupiah (IDR).
/// Memastikan format ribuan selalu menggunakan pemisah titik (.000).
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format angka nominal menjadi string pemisah ribuan dengan titik (contoh: 15.000).
  static String formatNominal(num? amount) {
    if (amount == null) return '0';
    final rounded = amount.round();
    final isNegative = rounded < 0;
    final absStr = rounded.abs().toString();
    final formatted = absStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return isNegative ? '-$formatted' : formatted;
  }

  /// Format angka nominal menjadi mata uang Rupiah lengkap (contoh: Rp 15.000).
  static String formatRupiah(num? amount, {String prefix = 'Rp '}) {
    if (amount == null) return '${prefix}0';
    final rounded = amount.round();
    final isNegative = rounded < 0;
    final absStr = rounded.abs().toString();
    final formatted = absStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return isNegative ? '-$prefix$formatted' : '$prefix$formatted';
  }

  /// Alias format mata uang (contoh: Rp 15.000).
  static String formatCurrency(num? amount, {String prefix = 'Rp '}) {
    return formatRupiah(amount, prefix: prefix);
  }

  /// Melakukan parsing dari teks string nominal (contoh: '15.000', 'Rp 15.000', '15000')
  /// menjadi angka numerik murni double.
  static double parseNominal(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final cleaned = text.replaceAll(RegExp(r'[^0-9\-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Melakukan parsing dari teks string nominal ke angka int.
  static int parseNominalInt(String? text) {
    return parseNominal(text).round();
  }
}

/// Helper fungsi top-level untuk kenyamanan pemanggilan langsung di seluruh UI.
String formatRupiah(num? amount) => CurrencyFormatter.formatRupiah(amount);
String formatCurrency(num? amount) => CurrencyFormatter.formatCurrency(amount);
String formatNominal(num? amount) => CurrencyFormatter.formatNominal(amount);
