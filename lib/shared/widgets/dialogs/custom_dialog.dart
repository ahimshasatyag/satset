import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../buttons/custom_button.dart';
import 'status_animation.dart';

/// Utilitas Dialog Kustom aplikasi SatSet dengan dukungan animasi status Lottie
class CustomDialog {
  CustomDialog._();

  /// Menampilkan dialog standar dengan ikon opsional
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Lanjutkan',
    String? cancelText = 'Batal',
    VoidCallback? onConfirm,
    IconData? icon = Icons.info_outline,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 36),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: CustomButton.outlined(
                        text: cancelText,
                        size: ButtonSize.medium,
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: CustomButton(
                      text: confirmText,
                      size: ButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(ctx, true);
                        onConfirm?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Menampilkan dialog status dengan animasi Lottie JSON
  static Future<bool?> showStatus({
    required BuildContext context,
    required StatusAnimationType type,
    required String title,
    required String message,
    String confirmText = 'Lanjutkan',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusAnimationWidget(type: type, size: 84),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: CustomButton.outlined(
                        text: cancelText,
                        size: ButtonSize.medium,
                        onPressed: () {
                          Navigator.pop(ctx, false);
                          onCancel?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: CustomButton(
                      text: confirmText,
                      size: ButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(ctx, true);
                        onConfirm?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pintasan Dialog Sukses (menggunakan Check Mark - Success.json)
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showStatus(
      context: context,
      type: StatusAnimationType.success,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  /// Pintasan Dialog Error (menggunakan Sign for error _ Flat style.json)
  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Tutup',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showStatus(
      context: context,
      type: StatusAnimationType.error,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Pintasan Dialog Peringatan (menggunakan Warning Status.json)
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    String? cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showStatus(
      context: context,
      type: StatusAnimationType.warning,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
