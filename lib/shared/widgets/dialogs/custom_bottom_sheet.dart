import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../buttons/custom_button.dart';
import 'status_animation.dart';

/// Utilitas Modal Bottom Sheet kustom aplikasi SatSet
class CustomBottomSheet {
  CustomBottomSheet._();

  /// Menampilkan modal bottom sheet dengan header terstruktur, drag handle,
  /// dan kontainer selaras tema.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header: Title & Close Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content
                    child,

                    // Actions
                    if (actions != null && actions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: actions
                            .map((action) => Expanded(child: action))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Menampilkan modal bottom sheet status dengan animasi Lottie JSON
  static Future<T?> showStatus<T>({
    required BuildContext context,
    required StatusAnimationType type,
    required String title,
    required String message,
    String confirmText = 'Mengerti',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Lottie Animation
                StatusAnimationWidget(type: type, size: 90),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    if (cancelText != null) ...[
                      Expanded(
                        child: CustomButton.outlined(
                          text: cancelText,
                          onPressed: () {
                            Navigator.pop(ctx);
                            onCancel?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: confirmText,
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pintasan Bottom Sheet Sukses (menggunakan Check Mark - Success.json)
  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Selesai',
    VoidCallback? onConfirm,
  }) {
    return showStatus<T>(
      context: context,
      type: StatusAnimationType.success,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  /// Pintasan Bottom Sheet Error (menggunakan Sign for error _ Flat style.json)
  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Coba Lagi',
    String? cancelText = 'Tutup',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showStatus<T>(
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

  /// Pintasan Bottom Sheet Peringatan (menggunakan Warning Status.json)
  static Future<T?> showWarning<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Lanjutkan',
    String? cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showStatus<T>(
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
