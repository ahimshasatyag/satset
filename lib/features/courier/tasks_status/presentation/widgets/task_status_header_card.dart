import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/pages/courier_barcode_scanner_page.dart';
import 'package:satset/features/courier/location_tracking/presentation/pages/courier_location_tracking_page.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/task_status_detail.dart';

class TaskStatusHeaderCard extends StatelessWidget {
  final TaskStatusDetail detail;
  final DateTime? lastUpdated;
  final VoidCallback? onRefresh;

  const TaskStatusHeaderCard({
    super.key,
    required this.detail,
    this.lastUpdated,
    this.onRefresh,
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
      case 'IN_TRANSIT':
      case 'PICKED_UP':
      case 'PICKUP_SCHEDULED':
        return BadgeStatus.warning;
      default:
        return BadgeStatus.info;
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Nomor Resi & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Resi',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            detail.trackingNumber,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: detail.trackingNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor resi berhasil disalin ke papan klip'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: detail.currentStatusName,
                    status: _resolveBadgeStatus(detail.currentStatusCode),
                  ),
                  if (detail.isWaitingPayment) ...[
                    const SizedBox(height: 4),
                    const StatusBadge(
                      label: 'Belum Bayar',
                      status: BadgeStatus.error,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Baris 2: Layanan & Tipe Tugas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Layanan',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.serviceTypeName ?? 'Standar',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipe Tugas',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.taskTypeLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Baris 3: Waktu Penugasan & Estimasi Tiba
          Row(
            children: [
              if (detail.assignedAt != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Penugasan',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(detail.assignedAt!),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              if (detail.estimatedArrival != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Tiba',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(detail.estimatedArrival!),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (detail.barcodeValue != null && detail.barcodeValue!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Barcode: ${detail.barcodeValue}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Pintasan Navigasi Barcode Scanner & Lokasi GPS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        child: const CourierBarcodeScannerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Pindai Barcode'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        child: const CourierLocationTrackingPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Lacak GPS'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Realtime indicator
          if (lastUpdated != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Supabase: ${_formatDateTime(lastUpdated!)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (onRefresh != null)
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Segarkan',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
