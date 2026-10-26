import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/courier_task_history_item.dart';

/// Kartu item riwayat tugas kurir yang informatif dan responsif
class CourierTaskHistoryCard extends StatelessWidget {
  final CourierTaskHistoryItem item;
  final VoidCallback onTap;

  const CourierTaskHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  BadgeStatus _resolveBadgeStatus(String code) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return BadgeStatus.success;
      case 'FAILED_DELIVERY':
      case 'CANCELLED':
      case 'RETURNED':
        return BadgeStatus.error;
      case 'OUT_FOR_DELIVERY':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        return BadgeStatus.brand;
      default:
        return BadgeStatus.warning;
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Badge Tipe Tugas & Status Akhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isPickup
                            ? AppColors.secondary.withValues(alpha: 0.12)
                            : AppColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isPickup
                                ? Icons.archive_outlined
                                : Icons.local_shipping_outlined,
                            size: 14,
                            color: item.isPickup
                                ? AppColors.secondary
                                : AppColors.tertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.isPickup ? 'PICKUP' : 'DELIVERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.isPickup
                                  ? AppColors.secondary
                                  : (isDark ? Colors.lightBlueAccent : AppColors.tertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: item.statusName,
                      status: _resolveBadgeStatus(item.statusCode),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Baris Nomor Resi & Tombol Salin
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.trackingNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item.trackingNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nomor Resi ${item.trackingNumber} disalin!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    // Layanan Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.serviceTypeName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Nama Pihak & Alamat Tujuan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.isPickup ? Icons.person_pin_circle_outlined : Icons.location_on_outlined,
                      size: 16,
                      color: item.isPickup ? AppColors.secondary : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.isPickup ? "Pengirim: " : "Penerima: "}${item.targetPersonName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.targetAddress}, ${item.targetCity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 4. Catatan Alasan Kegagalan / Pengembalian jika ada
                if (item.hasFailureReason) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: isDark ? 0.2 : 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Alasan: ${item.failureOrReturnReason}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.redAccent : AppColors.error,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(height: 10),

                // 5. Metadata Waktu (Ditugaskan & Selesai)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: isDark ? Colors.white54 : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selesai: ${_formatDateTime(item.primaryCompletionTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.lightBlueAccent : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark ? Colors.lightBlueAccent : AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
