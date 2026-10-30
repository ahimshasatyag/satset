import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';

/// Widget skeleton loading placeholder untuk Halaman Edit Akun (EditAccountPage) SatSet.
/// Menampilkan animasi shimmer halus menyerupai kartu foto profil avatar,
/// form field (Nama Lengkap, Email, No HP), dan tombol simpan.
class EditAccountSkeleton extends StatefulWidget {
  final ScrollPhysics? physics;

  const EditAccountSkeleton({
    super.key,
    this.physics,
  });

  @override
  State<EditAccountSkeleton> createState() => _EditAccountSkeletonState();
}

class _EditAccountSkeletonState extends State<EditAccountSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final baseColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = baseColor.withValues(alpha: _animation.value);

        return ListView(
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // 1. Shimmer Header Card (Avatar & Nama)
            _buildHeaderSkeleton(cardBg, borderColor, shimmerColor, isDark),
            const SizedBox(height: 20),

            // 2. Shimmer Formulir Card (Header section & 3 TextFields)
            _buildFormSkeleton(cardBg, borderColor, shimmerColor),
            const SizedBox(height: 28),

            // 3. Shimmer Tombol Simpan
            Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Shimmer Card Header Profil & Avatar
  Widget _buildHeaderSkeleton(
    Color cardBg,
    Color borderColor,
    Color shimmerColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lingkaran Avatar
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: shimmerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 14),

          // Nama Pengguna
          Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Card Formulir Input Akun
  Widget _buildFormSkeleton(
    Color cardBg,
    Color borderColor,
    Color shimmerColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Icon
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 15,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 210,
                    height: 11,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Field 1: Nama Lengkap
          _buildFieldSkeleton(shimmerColor, labelWidth: 90),
          const SizedBox(height: 16),

          // Field 2: Alamat Email
          _buildFieldSkeleton(shimmerColor, labelWidth: 80),
          const SizedBox(height: 16),

          // Field 3: Nomor Telepon
          _buildFieldSkeleton(shimmerColor, labelWidth: 100),
        ],
      ),
    );
  }

  /// Helper untuk shimmer field input
  Widget _buildFieldSkeleton(Color shimmerColor, {required double labelWidth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: labelWidth,
          height: 12,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}

