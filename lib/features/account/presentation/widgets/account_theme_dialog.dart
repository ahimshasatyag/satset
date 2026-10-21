import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class AccountThemeDialog extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const AccountThemeDialog({
    super.key,
    this.onToggleTheme,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onToggleTheme,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AccountThemeDialog(
        onToggleTheme: onToggleTheme,
        isDark: isDark,
      ),
    );
  }

  void _applyTheme(BuildContext context, ThemeMode mode) {
    Navigator.of(context).pop();

    // 1. Coba update via ThemeCubit jika tersedia di context
    try {
      context.read<ThemeCubit>().updateTheme(mode);
      return;
    } catch (_) {}

    // 2. Fallback ke callback onToggleTheme jika mode berbeda
    if (onToggleTheme != null) {
      if ((mode == ThemeMode.dark && !isDark) ||
          (mode == ThemeMode.light && isDark)) {
        onToggleTheme!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeMode? currentMode;
    try {
      currentMode = context.watch<ThemeCubit>().state;
    } catch (_) {
      currentMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor:
          isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Tema Tampilan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Konfigurasi AppTheme resmi SatSet Delivery.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Opsi 1: Mode Terang (Light Theme)
              _buildThemeOption(
                context: context,
                mode: ThemeMode.light,
                isSelected: currentMode == ThemeMode.light,
                icon: Icons.light_mode_rounded,
                iconColor: AppColors.secondary,
                title: 'Mode Terang (Light Theme)',
                description:
                    'Palet bersih dan cerah dari AppTheme.lightTheme, optimal untuk penggunaan siang hari.',
                isDarkContainer: isDarkMode,
              ),
              const SizedBox(height: 10),

              // Opsi 2: Mode Gelap (Dark Theme)
              _buildThemeOption(
                context: context,
                mode: ThemeMode.dark,
                isSelected: currentMode == ThemeMode.dark,
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.tertiary,
                title: 'Mode Gelap (Dark Theme)',
                description:
                    'Palet elegan navy slate dari AppTheme.darkTheme, nyaman di mata dan hemat daya.',
                isDarkContainer: isDarkMode,
              ),
              const SizedBox(height: 10),

              // Opsi 3: Ikuti Sistem
              _buildThemeOption(
                context: context,
                mode: ThemeMode.system,
                isSelected: currentMode == ThemeMode.system,
                icon: Icons.brightness_auto_rounded,
                iconColor: AppColors.primary,
                title: 'Ikuti Sistem Perangkat',
                description:
                    'Secara otomatis menyesuaikan tema dengan pengaturan sistem perangkat Anda.',
                isDarkContainer: isDarkMode,
              ),
              const SizedBox(height: 20),

              // Tombol Batal
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: 'Tutup',
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDarkContainer,
  }) {
    return InkWell(
      onTap: () => _applyTheme(context, mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDarkContainer ? 0.15 : 0.08)
              : (isDarkContainer
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDarkContainer
                    ? AppColors.borderDark
                    : AppColors.borderLight),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : (isDarkContainer
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkContainer
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
