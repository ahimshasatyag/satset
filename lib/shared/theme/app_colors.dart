import 'package:flutter/material.dart';

/// Palet warna tema aplikasi SatSet yang diekstrak dan diselaraskan secara presisi
/// dari logo resmi `LogoTextSatset.png`.
///
/// Karakteristik Warna:
/// - **Primary (Crimson Red / #B61330)**: Diambil dari teks "SATSET" dan ikon utama huruf "S",
///   melambangkan kecepatan, energi, dan identitas utama brand.
/// - **Secondary (Speed Orange / #D5741F)**: Diambil dari lengkungan swoosh akselerasi di bawah,
///   melambangkan dinamisme, kehangatan, dan kelincahan (sat-set).
/// - **Tertiary (Tech Navy / #213C5C)**: Diambil dari panah meluncur ke atas dan teks ".id",
///   melambangkan arah, ketepatan, teknologi, dan keandalan.
/// - **Text Dark (#20364F)**: Diambil dari teks tagline "Sat-Set Sampai, Hati Pun Santai.",
///   memberikan kontras teks yang elegan dan ramah di mata dibanding hitam pekat.
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. BRAND PRIMARY - CRIMSON RED (#B61330)
  // ===========================================================================
  static const Color primary = Color(0xFFB61330);
  static const Color primary50 = Color(0xFFFDF2F4);
  static const Color primary100 = Color(0xFFFCE4E7);
  static const Color primary200 = Color(0xFFF8BAC2);
  static const Color primary300 = Color(0xFFF18695);
  static const Color primary400 = Color(0xFFE34860);
  static const Color primary500 = Color(0xFFB61330); // Base Primary
  static const Color primary600 = Color(0xFF9E0D27);
  static const Color primary700 = Color(0xFF82081E);
  static const Color primary800 = Color(0xFF660516);
  static const Color primary900 = Color(0xFF4C030F);

  /// Material Color Swatch untuk primary red
  static const MaterialColor primarySwatch = MaterialColor(
    0xFFB61330,
    <int, Color>{
      50: primary50,
      100: primary100,
      200: primary200,
      300: primary300,
      400: primary400,
      500: primary500,
      600: primary600,
      700: primary700,
      800: primary800,
      900: primary900,
    },
  );

  // ===========================================================================
  // 2. BRAND SECONDARY - SPEED ORANGE (#D5741F)
  // ===========================================================================
  static const Color secondary = Color(0xFFD5741F);
  static const Color secondary50 = Color(0xFFFEF7EE);
  static const Color secondary100 = Color(0xFFFDECD7);
  static const Color secondary200 = Color(0xFFFBD5AC);
  static const Color secondary300 = Color(0xFFF6B574);
  static const Color secondary400 = Color(0xFFEE9239);
  static const Color secondary500 = Color(0xFFD5741F); // Base Secondary
  static const Color secondary600 = Color(0xFFB95D14);
  static const Color secondary700 = Color(0xFF94470F);
  static const Color secondary800 = Color(0xFF75360F);
  static const Color secondary900 = Color(0xFF56270E);

  // ===========================================================================
  // 3. BRAND TERTIARY - CORPORATE NAVY (#213C5C)
  // ===========================================================================
  static const Color tertiary = Color(0xFF213C5C);
  static const Color tertiary50 = Color(0xFFF1F5F9);
  static const Color tertiary100 = Color(0xFFE0EAF3);
  static const Color tertiary200 = Color(0xFFC2D4E6);
  static const Color tertiary300 = Color(0xFF94B5D4);
  static const Color tertiary400 = Color(0xFF5D8FBD);
  static const Color tertiary500 = Color(0xFF213C5C); // Base Tertiary
  static const Color tertiary600 = Color(0xFF1B324D);
  static const Color tertiary700 = Color(0xFF15273C);
  static const Color tertiary800 = Color(0xFF0E1A29);
  static const Color tertiary900 = Color(0xFF080F17);

  // ===========================================================================
  // 4. TYPOGRAPHY & TEXT COLORS
  // ===========================================================================
  /// Warna teks utama light mode (diambil dari warna teks slogan)
  static const Color textPrimaryLight = Color(0xFF20364F);
  static const Color textSecondaryLight = Color(0xFF5A6F84);
  static const Color textMutedLight = Color(0xFF8E9EB0);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  /// Warna teks dark mode
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // ===========================================================================
  // 5. SURFACES & BACKGROUNDS
  // ===========================================================================
  // Light Mode
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderFocusLight = Color(0xFFB61330);

  // Dark Mode (Elegan, berbasis deep navy slate)
  static const Color backgroundDark = Color(0xFF0D1520);
  static const Color surfaceDark = Color(0xFF131E2C);
  static const Color surfaceVariantDark = Color(0xFF1A283A);
  static const Color borderDark = Color(0xFF26394F);
  static const Color borderFocusDark = Color(0xFFE34860);

  // ===========================================================================
  // 6. SEMANTIC / STATUS COLORS
  // ===========================================================================
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

  // Common Constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ===========================================================================
  // 7. BRAND GRADIENTS (SELARAS DENGAN LOGO SATSET)
  // ===========================================================================
  /// Gradient utama merah ke oranye (mewakili visual logo 'S' dan akselerasi)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB61330), // Primary Red
      Color(0xFFD5741F), // Speed Orange
    ],
  );

  /// Gradient oranye ke amber (mewakili aksen kecepatan dan tombol aksi dinamis)
  static const LinearGradient speedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD5741F),
      Color(0xFFE88A36),
    ],
  );

  /// Gradient navy profesional (mewakili kartu header, banner, atau elemen tech)
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF213C5C),
      Color(0xFF132337),
    ],
  );

  /// Gradient tricolor penuh (Merah -> Oranye -> Navy)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB61330),
      Color(0xFFD5741F),
      Color(0xFF213C5C),
    ],
  );
}
