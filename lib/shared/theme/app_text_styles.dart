import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografi aplikasi SatSet yang dirancang proporsional, terbaca jelas,
/// dan selaras dengan hierarki desain modern Material 3.
/// Menggunakan warna teks default [AppColors.textPrimaryLight] yang bersumber
/// langsung dari tipografi logo SatSet.
class AppTextStyles {
  AppTextStyles._();

  // ===========================================================================
  // 1. DISPLAY STYLES (Untuk teks hero atau angka besar)
  // ===========================================================================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.15,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.textPrimaryLight,
  );

  // ===========================================================================
  // 2. HEADLINE STYLES (Untuk judul layar utama & section penting)
  // ===========================================================================
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.28,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimaryLight,
  );

  // ===========================================================================
  // 3. TITLE STYLES (Untuk judul kartu, app bar, dialog)
  // ===========================================================================
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimaryLight,
  );

  // ===========================================================================
  // 4. BODY STYLES (Untuk teks bacaan, paragraf, deskripsi form)
  // ===========================================================================
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondaryLight,
  );

  // ===========================================================================
  // 5. LABEL STYLES (Untuk tombol, tag, badge, input label)
  // ===========================================================================
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textSecondaryLight,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.textMutedLight,
  );

  // ===========================================================================
  // 6. BRAND TEXT STYLES (Gaya khas brand SatSet)
  // ===========================================================================
  /// Gaya teks logo "SATSET" dengan aksen merah bold
  static const TextStyle brandTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    color: AppColors.primary,
  );

  /// Gaya teks domain ".id" dengan aksen navy tebal
  static const TextStyle brandDomain = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    color: AppColors.tertiary,
  );

  /// Gaya teks slogan "Sat-Set Sampai, Hati Pun Santai."
  static const TextStyle brandSlogan = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textPrimaryLight,
  );

  // ===========================================================================
  // 7. BUILDER MATERIAL TEXT THEME
  // ===========================================================================
  /// TextTheme untuk Light Mode
  static TextTheme get lightTextTheme => const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  /// TextTheme untuk Dark Mode (warna disesuaikan dengan [AppColors.textPrimaryDark])
  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.textPrimaryDark),
        displayMedium: displayMedium.copyWith(color: AppColors.textPrimaryDark),
        displaySmall: displaySmall.copyWith(color: AppColors.textPrimaryDark),
        headlineLarge: headlineLarge.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: headlineMedium.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: titleLarge.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: titleMedium.copyWith(color: AppColors.textPrimaryDark),
        titleSmall: titleSmall.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: labelLarge.copyWith(color: AppColors.textPrimaryDark),
        labelMedium: labelMedium.copyWith(color: AppColors.textSecondaryDark),
        labelSmall: labelSmall.copyWith(color: AppColors.textMutedDark),
      );
}
