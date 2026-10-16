import 'package:flutter/material.dart';
import '../..//theme/theme.dart';

/// Varian kartu kustom [CustomCard]
enum CardVariant {
  /// Kartu bergaris tepi halus (gaya modern Material 3)
  outlined,

  /// Kartu dengan bayangan elevasi lembut
  elevated,

  /// Kartu berwarna latar kontras lembut tanpa garis
  filled,

  /// Kartu dengan latar gradient brand SatSet
  gradient,
}

/// Widget kartu kustom aplikasi SatSet dengan fleksibilitas varian,
/// animasi interaksi klik (*ink ripple*), dan penyelarasan tema otomatis.
class CustomCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.variant = CardVariant.outlined,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.color,
    this.gradient,
    this.border,
    this.width,
    this.height,
  });

  /// Konstruktor kartu hero / banner dengan gradient merah-ke-oranye SatSet
  const CustomCard.banner({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
  })  : variant = CardVariant.gradient,
        color = null,
        gradient = AppColors.primaryGradient,
        border = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    Color defaultBgColor;
    Border? defaultBorder = border;
    List<BoxShadow>? boxShadow;
    Gradient? effectiveGradient = gradient;

    switch (variant) {
      case CardVariant.outlined:
        defaultBgColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
        defaultBorder ??= Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        );
        break;

      case CardVariant.elevated:
        defaultBgColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
        boxShadow = [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.textPrimaryLight.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;

      case CardVariant.filled:
        defaultBgColor = color ??
            (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);
        break;

      case CardVariant.gradient:
        defaultBgColor = Colors.transparent;
        effectiveGradient ??= AppColors.primaryGradient;
        boxShadow = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? defaultBgColor : null,
        gradient: effectiveGradient,
        borderRadius: radius,
        border: defaultBorder,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
