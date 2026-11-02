/// Utility pemformat mata uang Rupiah (IDR) untuk Admin SatSet Delivery
class AdminCurrencyFormatter {
  AdminCurrencyFormatter._();

  /// Format angka integer / double menjadi format mata uang Rupiah standar
  /// Contoh: 150000 -> "Rp 150.000"
  static String formatRupiah(num? amount, {bool includeSymbol = true}) {
    if (amount == null) return includeSymbol ? 'Rp 0' : '0';

    final isNegative = amount < 0;
    final absVal = amount.abs().round();
    final strVal = absVal.toString();

    final buffer = StringBuffer();
    int count = 0;

    for (int i = strVal.length - 1; i >= 0; i--) {
      buffer.write(strVal[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }

    final formattedNumber = buffer.toString().split('').reversed.join('');
    final sign = isNegative ? '-' : '';

    return includeSymbol
        ? (isNegative ? '-Rp $formattedNumber' : 'Rp $formattedNumber')
        : '$sign$formattedNumber';
  }

  /// Format ringkas untuk angka besar (misal di kartu statistik)
  /// Contoh: 1.500.000 -> "Rp 1,5 Jt", 25.000 -> "Rp 25 Rb"
  static String formatCompactRupiah(num? amount) {
    if (amount == null || amount == 0) return 'Rp 0';
    final val = amount.toDouble();

    if (val >= 1000000000) {
      return 'Rp ${(val / 1000000000).toStringAsFixed(1).replaceAll('.0', '')} M';
    } else if (val >= 1000000) {
      return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll('.0', '')} Jt';
    } else if (val >= 1000) {
      return 'Rp ${(val / 1000).toStringAsFixed(1).replaceAll('.0', '')} Rb';
    }
    return formatRupiah(amount);
  }
}

