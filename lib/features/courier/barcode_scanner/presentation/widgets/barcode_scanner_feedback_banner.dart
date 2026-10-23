import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/barcode_scan_result.dart';

/// Banner umpan balik visual hasil pemindaian barcode yang ditolak,
/// tidak valid, bukan tanggung jawab, atau mengalami kendala sistem.
class BarcodeScannerFeedbackBanner extends StatelessWidget {
  final BarcodeScanResult result;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;
  final VoidCallback onManualInput;
  final VoidCallback? onForceScan;

  const BarcodeScannerFeedbackBanner({
    super.key,
    required this.result,
    required this.onDismiss,
    required this.onRetry,
    required this.onManualInput,
    this.onForceScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final info = _resolveFeedbackInfo(result.status, colorScheme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.backgroundColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Ikon, Judul, & Tombol Tutup
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: info.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info.icon,
                  color: info.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: info.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pesan Penjelasan
          Text(
            result.message,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          // Petunjuk Lanjutan
          if (result.guidance != null) ...[
            const SizedBox(height: 4),
            Text(
              result.guidance!,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Tombol Tindakan
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (result.status == BarcodeScanStatus.duplicate && onForceScan != null) ...[
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tetap Buka'),
                  onPressed: onForceScan,
                ),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: onManualInput,
                child: const Text('Input Manual'),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Pindai Ulang',
                size: ButtonSize.small,
                variant: ButtonVariant.primary,
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                onPressed: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _FeedbackInfo _resolveFeedbackInfo(
    BarcodeScanStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case BarcodeScanStatus.unregistered:
        return _FeedbackInfo(
          title: 'Barcode Tidak Dikenal',
          icon: Icons.search_off_rounded,
          accentColor: colorScheme.secondary,
          borderColor: colorScheme.secondary.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF2C1E14) : const Color(0xFFFEF7EE),
        );
      case BarcodeScanStatus.notAssigned:
        return _FeedbackInfo(
          title: 'Bukan Tanggung Jawab Kurir',
          icon: Icons.person_off_rounded,
          accentColor: colorScheme.error,
          borderColor: colorScheme.error.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF2A1418) : const Color(0xFFFDF2F4),
        );
      case BarcodeScanStatus.invalidStatus:
        return _FeedbackInfo(
          title: 'Status Tidak Diizinkan',
          icon: Icons.block_rounded,
          accentColor: colorScheme.onSurfaceVariant,
          borderColor: colorScheme.outline.withOpacity(0.5),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF222428) : const Color(0xFFF4F5F7),
        );
      case BarcodeScanStatus.duplicate:
        return _FeedbackInfo(
          title: 'Barcode Pernah Dipindai',
          icon: Icons.replay_rounded,
          accentColor: AppColors.info,
          borderColor: AppColors.info.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF142434) : const Color(0xFFEFF8FF),
        );
      case BarcodeScanStatus.permissionDenied:
        return _FeedbackInfo(
          title: 'Izin Kamera Ditolak',
          icon: Icons.no_photography_rounded,
          accentColor: colorScheme.error,
          borderColor: colorScheme.error.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF2A1418) : const Color(0xFFFDF2F4),
        );
      case BarcodeScanStatus.cameraUnavailable:
        return _FeedbackInfo(
          title: 'Kamera Tidak Tersedia',
          icon: Icons.videocam_off_rounded,
          accentColor: colorScheme.secondary,
          borderColor: colorScheme.secondary.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF2C1E14) : const Color(0xFFFEF7EE),
        );
      case BarcodeScanStatus.serverError:
        return _FeedbackInfo(
          title: 'Kendala Sistem / Jaringan',
          icon: Icons.cloud_off_rounded,
          accentColor: colorScheme.error,
          borderColor: colorScheme.error.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF2A1418) : const Color(0xFFFDF2F4),
        );
      case BarcodeScanStatus.success:
        return _FeedbackInfo(
          title: 'Pemindaian Berhasil',
          icon: Icons.check_circle_outline_rounded,
          accentColor: AppColors.success,
          borderColor: AppColors.success.withOpacity(0.4),
          backgroundColor: (isDark) =>
              isDark ? const Color(0xFF12281E) : const Color(0xFFECFDF3),
        );
    }
  }
}

class _FeedbackInfo {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color borderColor;
  final Color Function(bool isDark) backgroundColor;

  _FeedbackInfo({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.borderColor,
    required this.backgroundColor,
  });
}
