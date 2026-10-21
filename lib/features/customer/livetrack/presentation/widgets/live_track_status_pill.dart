import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class LiveTrackStatusPill extends StatelessWidget {
  final int activeCourierCount;
  final bool isGpsAvailable;
  final String freshnessText;
  final bool isDisconnected;
  final bool hasShipments;

  const LiveTrackStatusPill({
    super.key,
    required this.activeCourierCount,
    this.isGpsAvailable = false,
    this.freshnessText = '',
    this.isDisconnected = false,
    this.hasShipments = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color indicatorColor;
    String text;

    if (isDisconnected) {
      indicatorColor = AppColors.error;
      text = 'Koneksi Terputus';
    } else if (!hasShipments) {
      indicatorColor = isDark ? Colors.white38 : Colors.black38;
      text = '0 Pengiriman';
    } else if (isGpsAvailable) {
      indicatorColor = AppColors.success;
      text = freshnessText.isNotEmpty
          ? 'GPS Kurir Aktif • $freshnessText'
          : '$activeCourierCount Kurir Aktif';
    } else {
      indicatorColor = AppColors.secondary;
      text = 'GPS Belum Aktif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            .withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
