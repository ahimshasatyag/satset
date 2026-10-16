import 'package:flutter/material.dart';
import '../..//theme/theme.dart';

/// Status semantik untuk [StatusBadge]
enum BadgeStatus {
  /// Status berhasil / selesai / terkirim
  success,

  /// Status proses / pending / sedang berjalan
  warning,

  /// Status error / gagal / dibatalkan
  error,

  /// Status informasi umum
  info,

  /// Status khusus layanan unggulan SatSet (Sat-Set Instant / Prioritas)
  brand,
}

/// Widget badge status kustom aplikasi SatSet untuk menampilkan label ringkas,
/// status pengiriman, tag promosi, dan indikator dengan warna selaras tema.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final bool showDot;
  final Widget? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.info,
    this.showDot = true,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  });

  /// Shortcut badge SatSet Brand
  const StatusBadge.satset({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  }) : status = BadgeStatus.brand;

  /// Shortcut badge sukses
  const StatusBadge.success({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  }) : status = BadgeStatus.success;

  /// Shortcut badge warning/proses
  const StatusBadge.warning({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  }) : status = BadgeStatus.warning;

  /// Shortcut badge error
  const StatusBadge.error({
    super.key,
    required this.label,
    this.showDot = true,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  }) : status = BadgeStatus.error;

  Color _getBgColor() {
    switch (status) {
      case BadgeStatus.success:
        return AppColors.successLight;
      case BadgeStatus.warning:
        return AppColors.warningLight;
      case BadgeStatus.error:
        return AppColors.errorLight;
      case BadgeStatus.info:
        return AppColors.infoLight;
      case BadgeStatus.brand:
        return AppColors.primary100;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case BadgeStatus.success:
        return AppColors.successDark;
      case BadgeStatus.warning:
        return AppColors.warningDark;
      case BadgeStatus.error:
        return AppColors.errorDark;
      case BadgeStatus.info:
        return AppColors.infoDark;
      case BadgeStatus.brand:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBgColor();
    final textColor = _getTextColor();
    final radius = borderRadius ?? BorderRadius.circular(20);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showDot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
        ),
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
          ),
          child: content,
        ),
      ),
    );
  }
}
