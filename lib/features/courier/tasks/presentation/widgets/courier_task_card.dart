import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/courier_task.dart';

class CourierTaskCard extends StatelessWidget {
  final CourierTask task;
  final VoidCallback onTap;
  final VoidCallback? onQuickAction;

  const CourierTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onQuickAction,
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
      case 'PICKUP_SCHEDULED':
      case 'CONFIRMED':
      case 'PENDING':
      default:
        return BadgeStatus.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                // 1. Baris Atas: Tipe Tugas (Pickup/Delivery) & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isPickup
                            ? AppColors.secondary.withValues(alpha: 0.12)
                            : AppColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            task.isPickup
                                ? Icons.archive_outlined
                                : Icons.local_shipping_outlined,
                            size: 14,
                            color: task.isPickup
                                ? AppColors.secondary
                                : AppColors.tertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            task.isPickup ? 'PICKUP' : 'DELIVERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: task.isPickup
                                  ? AppColors.secondary
                                  : (isDark ? Colors.lightBlueAccent : AppColors.tertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: task.statusName,
                      status: _resolveBadgeStatus(task.statusCode),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Baris Resi & Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          task.trackingNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: task.trackingNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nomor Resi ${task.trackingNumber} disalin!'),
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
                    Text(
                      task.serviceTypeName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Nama Pihak Tujuan (Pengirim untuk pickup, Penerima untuk delivery)
                Row(
                  children: [
                    Icon(
                      task.isPickup ? Icons.person_pin_circle_outlined : Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${task.targetPersonName} (${task.targetPersonPhone})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 4. Alamat Tujuan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${task.targetAddress}, ${task.targetCity}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 5. Bagian Bawah: Informasi Paket & Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Berat: ${task.weightFormatted}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        if (task.estimatedArrival != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Est. Tiba: ${_formatTime(task.estimatedArrival!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: onQuickAction ?? onTap,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text(
                        task.taskGroup == CourierTaskGroup.completed
                            ? 'Lihat Detail'
                            : 'Proses Tugas',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}
