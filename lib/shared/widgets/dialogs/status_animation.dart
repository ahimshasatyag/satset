import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:satset/shared/theme/theme.dart';

/// Path aset animasi JSON Lottie untuk status dialog & bottom sheet
class AppAnimationAssets {
  AppAnimationAssets._();

  static const String success = 'assets/icon/Check Mark - Success.json';
  static const String error = 'assets/icon/Sign for error _ Flat style.json';
  static const String warning = 'assets/icon/Warning Status.json';
}

/// Tipe status animasi feedback
enum StatusAnimationType {
  /// Animasi centang sukses (Check Mark - Success.json)
  success,

  /// Animasi silang error (Sign for error _ Flat style.json)
  error,

  /// Animasi tanda seru peringatan (Warning Status.json)
  warning,
}

/// Alias agar kompatibel ke belakang
typedef BottomSheetDialogType = StatusAnimationType;

/// Widget mandiri untuk merender animasi status yang stabil & aman dari WebGL context loss
class StatusAnimationWidget extends StatelessWidget {
  final StatusAnimationType type;
  final double size;
  final bool repeat;

  const StatusAnimationWidget({
    super.key,
    required this.type,
    this.size = 80.0,
    this.repeat = false,
  });

  String get _assetPath {
    switch (type) {
      case StatusAnimationType.success:
        return AppAnimationAssets.success;
      case StatusAnimationType.error:
        return AppAnimationAssets.error;
      case StatusAnimationType.warning:
        return AppAnimationAssets.warning;
    }
  }

  IconData get _icon {
    switch (type) {
      case StatusAnimationType.success:
        return Icons.check_circle_rounded;
      case StatusAnimationType.error:
        return Icons.cancel_rounded;
      case StatusAnimationType.warning:
        return Icons.warning_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case StatusAnimationType.success:
        return AppColors.success;
      case StatusAnimationType.error:
        return AppColors.error;
      case StatusAnimationType.warning:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pada platform Web (CanvasKit), parser Lottie JSON sering menyebabkan
    // memory access out of bounds dan WebGL context loss saat tab switching.
    // Gunakan animasi native Flutter yang halus, ringan, dan 100% stabil.
    if (kIsWeb) {
      return SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _icon,
                    size: size * 0.58,
                    color: _color,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _assetPath,
        width: size,
        height: size,
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: size * 0.55,
                color: _color,
              ),
            ),
          );
        },
      ),
    );
  }
}
