import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/buttons/custom_button.dart';
import '../../domain/entities/tracking_service_status.dart';

/// Banner edukatif yang menjelaskan kebutuhan akses lokasi dan memandu kurir
class CourierLocationPermissionBanner extends StatelessWidget {
  final TrackingGpsStatus status;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  const CourierLocationPermissionBanner({
    super.key,
    required this.status,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGpsDisabled = status == TrackingGpsStatus.gpsDisabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGpsDisabled ? Icons.location_off_rounded : Icons.security_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isGpsDisabled
                      ? 'Layanan GPS Perangkat Mati'
                      : 'Izin Akses Lokasi Diperlukan',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isGpsDisabled
                ? 'Aplikasi memerlukan GPS aktif untuk memantau rute pengantaran dan mengabarkan posisi paket kepada pelanggan secara akurat.'
                : 'SatSet Delivery membutuhkan izin lokasi saat aplikasi digunakan agar kurir dapat memperbarui posisi pengantaran tugas aktif.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isGpsDisabled)
                Expanded(
                  child: CustomButton(
                    text: 'Buka Pengaturan GPS',
                    prefixIcon: const Icon(Icons.settings_rounded, size: 16, color: Colors.white),
                    onPressed: onOpenSettings,
                  ),
                )
              else ...[
                Expanded(
                  child: CustomButton(
                    text: 'Berikan Izin Lokasi',
                    prefixIcon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    onPressed: onRequestPermission,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pengaturan Aplikasi',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: onOpenSettings,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
