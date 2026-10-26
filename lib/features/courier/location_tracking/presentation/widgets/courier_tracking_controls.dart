import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Kontrol mengambang pada peta pelacakan lokasi kurir.
/// Memfasilitasi zoom in, zoom out, pemusatan ke posisi kurir,
/// pemusatan ke titik tujuan, serta fit bounds (menampilkan kurir & tujuan sekaligus).
class CourierTrackingControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterCourier;
  final VoidCallback? onCenterDestination;
  final VoidCallback? onFitBounds;
  final bool isCourierLocationAvailable;
  final bool isDestinationAvailable;

  const CourierTrackingControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterCourier,
    this.onCenterDestination,
    this.onFitBounds,
    this.isCourierLocationAvailable = true,
    this.isDestinationAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            .withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onPressed: onZoomIn,
            tooltip: 'Perbesar Peta',
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onPressed: onZoomOut,
            tooltip: 'Perkecil Peta',
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Pusatkan ke lokasi kurir
          IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              size: 20,
              color: isCourierLocationAvailable
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            onPressed: isCourierLocationAvailable ? onCenterCourier : null,
            tooltip: 'Pusatkan ke Posisi Saya',
          ),
          // Pusatkan ke tujuan tugas jika tersedia
          if (isDestinationAvailable && onCenterDestination != null) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            IconButton(
              icon: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: AppColors.secondary,
              ),
              onPressed: onCenterDestination,
              tooltip: 'Pusatkan ke Titik Tujuan',
            ),
          ],
          // Fit bounds (menampilkan kurir dan tujuan sekaligus)
          if (isCourierLocationAvailable && isDestinationAvailable && onFitBounds != null) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            IconButton(
              icon: Icon(
                Icons.zoom_out_map_rounded,
                size: 19,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              onPressed: onFitBounds,
              tooltip: 'Tampilkan Seluruh Rute',
            ),
          ],
        ],
      ),
    );
  }
}
