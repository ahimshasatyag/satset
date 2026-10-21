import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class LiveTrackMapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  const LiveTrackMapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
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
          IconButton(
            icon: const Icon(
              Icons.my_location_rounded,
              size: 19,
              color: AppColors.primary,
            ),
            onPressed: onCenter,
            tooltip: 'Pusatkan ke Titik Pengiriman',
          ),
        ],
      ),
    );
  }
}
