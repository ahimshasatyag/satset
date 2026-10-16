import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../..//theme/theme.dart';

/// App Bar kustom aplikasi SatSet dengan opsi latar belakang bersih atau gradient brand,
/// tombol kembali berdesain rounded, dan integrasi tipografi konsisten.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final bool useGradient;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.showBackButton = true,
    this.onBackTap,
    this.actions,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.useGradient = false,
    this.leading,
  });

  /// Pintasan App Bar dengan Brand Gradient (Merah ke Oranye SatSet)
  const CustomAppBar.gradient({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.showBackButton = true,
    this.onBackTap,
    this.actions,
    this.bottom,
    this.elevation = 0,
    this.leading,
  })  : useGradient = true,
        backgroundColor = null;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton && canPop) {
      effectiveLeading = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: useGradient
                ? Colors.white.withValues(alpha: 0.15)
                : (isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: useGradient
                  ? AppColors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            onPressed: onBackTap ?? () => Navigator.maybePop(context),
            tooltip: 'Kembali',
          ),
        ),
      );
    }

    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null) {
      effectiveTitle = Text(
        title!,
        style: AppTextStyles.titleLarge.copyWith(
          color: useGradient
              ? AppColors.white
              : (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final barColor = backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return AppBar(
      title: effectiveTitle,
      centerTitle: centerTitle,
      leading: effectiveLeading,
      actions: actions,
      bottom: bottom,
      elevation: elevation,
      scrolledUnderElevation: 0.5,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            useGradient || isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            useGradient || isDark ? Brightness.dark : Brightness.light,
      ),
      backgroundColor: useGradient ? Colors.transparent : barColor,
      flexibleSpace: useGradient
          ? Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            )
          : null,
    );
  }
}
