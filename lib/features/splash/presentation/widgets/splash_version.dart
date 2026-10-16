import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget teks informasi versi aplikasi di bagian bawah Splash Screen
class SplashVersion extends StatelessWidget {
  final String version;

  const SplashVersion({
    super.key,
    this.version = '1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Versi $version',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026 SatSet.id Express Logistics',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
