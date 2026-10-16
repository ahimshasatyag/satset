import 'package:flutter/material.dart';
import '../..//theme/theme.dart';

/// Jenis varian tampilan tombol [CustomButton]
enum ButtonVariant {
  /// Tombol utama dengan latar belakang warna Crimson Red brand
  primary,

  /// Tombol aksen dengan latar belakang warna Speed Orange
  secondary,

  /// Tombol korporat dengan latar belakang warna Tech Navy
  tertiary,

  /// Tombol dengan gradient brand (Merah ➔ Oranye)
  gradient,

  /// Tombol bergaris tepi dengan latar belakang transparan
  outlined,

  /// Tombol teks tanpa garis tepi dan tanpa latar belakang
  ghost,
}

/// Ukuran tombol [CustomButton]
enum ButtonSize {
  /// Tinggi 38dp, padding ringkas, font 12sp
  small,

  /// Tinggi 48dp, padding standar, font 14sp
  medium,

  /// Tinggi 56dp, padding luas, font 16sp
  large,
}

/// Widget tombol kustom aplikasi SatSet dengan animasi interaktif saat ditekan,
/// berbagai varian brand, indikator pemuatan (*loading indicator*), dan penanganan ikon.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Pintasan untuk tombol sekunder (*Speed Orange*)
  const CustomButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius,
  }) : variant = ButtonVariant.secondary;

  /// Pintasan untuk tombol dengan gradient dinamis
  const CustomButton.gradient({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius,
  }) : variant = ButtonVariant.gradient;

  /// Pintasan untuk tombol outlined
  const CustomButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius,
  }) : variant = ButtonVariant.outlined;

  /// Pintasan untuk tombol ghost / tanpa latar belakang
  const CustomButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius,
  }) : variant = ButtonVariant.ghost;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) {
      _animController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _animController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isEnabled) {
      _animController.reverse();
    }
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  double get _defaultHeight {
    switch (widget.size) {
      case ButtonSize.small:
        return 38;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    TextStyle base;
    switch (widget.size) {
      case ButtonSize.small:
        base = AppTextStyles.labelMedium;
        break;
      case ButtonSize.medium:
        base = AppTextStyles.labelLarge;
        break;
      case ButtonSize.large:
        base = AppTextStyles.titleMedium;
        break;
    }

    Color color;
    if (!_isEnabled) {
      color = AppColors.textDisabledLight;
    } else {
      switch (widget.variant) {
        case ButtonVariant.primary:
        case ButtonVariant.secondary:
        case ButtonVariant.tertiary:
        case ButtonVariant.gradient:
          color = AppColors.white;
          break;
        case ButtonVariant.outlined:
          color = AppColors.primary;
          break;
        case ButtonVariant.ghost:
          color = AppColors.textPrimaryLight;
          break;
      }
    }

    return base.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    if (!_isEnabled) {
      if (widget.variant == ButtonVariant.outlined) {
        return BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.borderLight),
        );
      }
      if (widget.variant == ButtonVariant.ghost) {
        return BoxDecoration(borderRadius: radius);
      }
      return BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: radius,
      );
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return BoxDecoration(
          color: AppColors.primary,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case ButtonVariant.secondary:
        return BoxDecoration(
          color: AppColors.secondary,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case ButtonVariant.tertiary:
        return BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case ButtonVariant.gradient:
        return BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ButtonVariant.outlined:
        return BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
      case ButtonVariant.ghost:
        return BoxDecoration(borderRadius: radius);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context);
    final height = widget.height ?? _defaultHeight;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    Widget childContent;
    if (widget.isLoading) {
      final spinnerColor = (widget.variant == ButtonVariant.outlined ||
              widget.variant == ButtonVariant.ghost)
          ? AppColors.primary
          : AppColors.white;

      childContent = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else {
      final items = <Widget>[];
      if (widget.prefixIcon != null) {
        items.add(widget.prefixIcon!);
        items.add(const SizedBox(width: 8));
      }
      items.add(
        Flexible(
          child: Text(
            widget.text,
            style: textStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      if (widget.suffixIcon != null) {
        items.add(const SizedBox(width: 8));
        items.add(widget.suffixIcon!);
      }

      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      );
    }

    final buttonWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: height,
          decoration: _getDecoration(context),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isEnabled ? widget.onPressed : null,
              borderRadius: borderRadius,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size == ButtonSize.small ? 14 : 20,
                ),
                child: Center(child: childContent),
              ),
            ),
          ),
        ),
      ),
    );

    return buttonWidget;
  }
}
