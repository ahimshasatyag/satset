import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget tombol alternatif login melalui media sosial (Google & Apple)
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Divider "atau masuk dengan"
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'atau masuk dengan',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Tombol Google
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onGooglePressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Google Logo Kustom (Multi-color G)
                    _buildGoogleLogo(),
                    const SizedBox(width: 12),
                    Text(
                      'Masuk dengan Google',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Logo Google resmi yang digambar dengan Canvas/CustomPaint agar jernih dan bebas dependensi SVG
  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Gambar segmen luar Google 'G'
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Biru (Kanan atas & garis horizontal tengah)
    canvas.drawArc(rect, -0.785, 1.57, true, paintBlue);
    // Hijau (Bawah)
    canvas.drawArc(rect, 0.785, 1.57, true, paintGreen);
    // Kuning (Kiri)
    canvas.drawArc(rect, 2.356, 1.57, true, paintYellow);
    // Merah (Atas)
    canvas.drawArc(rect, 3.927, 1.57, true, paintRed);

    // Lubang lingkaran putih di tengah
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.58, holePaint);

    // Bilah biru horizontal ke kanan
    final barRect = Rect.fromLTRB(
      center.dx,
      center.dy - (radius * 0.22),
      w,
      center.dy + (radius * 0.22),
    );
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
