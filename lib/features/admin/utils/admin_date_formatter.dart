/// Utility pemformat tanggal dan waktu Indonesia untuk Admin SatSet Delivery
class AdminDateFormatter {
  AdminDateFormatter._();

  static const List<String> _bulanIndo = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _bulanIndoShort = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Format tanggal lengkap: 02 November 2026
  static String formatFullDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _bulanIndo[local.month];
    final y = local.year;
    return '$d $m $y';
  }

  /// Format tanggal pendek: 02 Nov 2026
  static String formatShortDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _bulanIndoShort[local.month];
    final y = local.year;
    return '$d $m $y';
  }

  /// Format tanggal dan waktu: 02 Nov 2026, 14:30 WIB
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _bulanIndoShort[local.month];
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$min WIB';
  }

  /// Format jam saja: 14:30 WIB
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$h:$min WIB';
  }

  /// Format selisih waktu relatif: "5 menit yang lalu", "2 jam yang lalu", "Kemarin"
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return formatShortDate(dateTime);
    }
  }
}

