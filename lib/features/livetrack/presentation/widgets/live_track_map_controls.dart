import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';

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
        color: (isDark ? Colors.black87 : Colors.white).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: onZoomIn,
            tooltip: 'Perbesar',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: onZoomOut,
            tooltip: 'Perkecil',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(
              Icons.my_location_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            onPressed: onCenter,
            tooltip: 'Pusatkan Peta',
          ),
        ],
      ),
    );
  }
}
