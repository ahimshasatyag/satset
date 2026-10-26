import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/tracking_service_status.dart';

/// Bilah status indikator operasional GPS dan akurasi pelacakan kurir
class CourierTrackingStatusBar extends StatelessWidget {
  final TrackingGpsStatus status;
  final CourierLocation? location;
  final DateTime? lastUpdatedTime;
  final VoidCallback? onRefresh;

  const CourierTrackingStatusBar({
    super.key,
    required this.status,
    this.location,
    this.lastUpdatedTime,
    this.onRefresh,
  });

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Belum diperbarui';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'Baru saja';
    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB';
  }

  Color _getStatusColor() {
    switch (status) {
      case TrackingGpsStatus.active:
        return AppColors.success;
      case TrackingGpsStatus.paused:
      case TrackingGpsStatus.idle:
        return AppColors.warning;
      case TrackingGpsStatus.acquiring:
        return AppColors.info;
      case TrackingGpsStatus.gpsDisabled:
      case TrackingGpsStatus.permissionDenied:
      case TrackingGpsStatus.permissionDeniedForever:
      case TrackingGpsStatus.error:
        return AppColors.error;
      case TrackingGpsStatus.noActiveTask:
      case TrackingGpsStatus.offline:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case TrackingGpsStatus.active:
        return Icons.satellite_alt_rounded;
      case TrackingGpsStatus.paused:
      case TrackingGpsStatus.idle:
        return Icons.pause_circle_outline_rounded;
      case TrackingGpsStatus.acquiring:
        return Icons.sync_rounded;
      case TrackingGpsStatus.gpsDisabled:
        return Icons.location_off_rounded;
      case TrackingGpsStatus.permissionDenied:
      case TrackingGpsStatus.permissionDeniedForever:
        return Icons.gpp_bad_rounded;
      case TrackingGpsStatus.offline:
        return Icons.wifi_off_rounded;
      case TrackingGpsStatus.noActiveTask:
        return Icons.inbox_outlined;
      case TrackingGpsStatus.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dot Indikator Berdenyut
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Label Status & Waktu Terakhir
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(_getStatusIcon(), size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location != null
                      ? 'Akurasi: ${location!.accuracyLabel} • ${_formatTimeAgo(lastUpdatedTime)}'
                      : 'Pembaruan: ${_formatTimeAgo(lastUpdatedTime)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Refresh Lokasi
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Perbarui Lokasi',
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onRefresh,
            ),
        ],
      ),
    );
  }
}
