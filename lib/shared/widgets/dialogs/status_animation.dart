import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/theme.dart';

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

/// Widget mandiri untuk merender animasi Lottie dengan ukuran fleksibel & fallback ikon
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

  IconData get _fallbackIcon {
    switch (type) {
      case StatusAnimationType.success:
        return Icons.check_circle_outline;
      case StatusAnimationType.error:
        return Icons.error_outline;
      case StatusAnimationType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  Color get _fallbackColor {
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
                color: _fallbackColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _fallbackIcon,
                size: size * 0.55,
                color: _fallbackColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
