import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import 'account_menu_card.dart';

class AccountSkeleton extends StatefulWidget {
  final bool isCourier;
  final ScrollPhysics? physics;

  const AccountSkeleton({
    super.key,
    this.isCourier = false,
    this.physics,
  });

  @override
  State<AccountSkeleton> createState() => _AccountSkeletonState();
}

class _AccountSkeletonState extends State<AccountSkeleton>
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = baseColor.withValues(alpha: _animation.value);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          children: [
            // 1. Shimmer Header Profil Pengguna
            _buildHeaderSkeleton(shimmerColor, isDark),
            const SizedBox(height: 24),

            // 2. Shimmer Bagian 1: Pengiriman & Alamat (Hanya untuk Customer / jika !isCourier)
            if (!widget.isCourier) ...[
              _buildSectionTitle(shimmerColor, width: 140),
              const SizedBox(height: 10),
              AccountMenuCard(
                children: [
                  _buildMenuItemSkeleton(shimmerColor, titleWidth: 150, subtitleWidth: 220),
                  const Divider(height: 1),
                  _buildMenuItemSkeleton(shimmerColor, titleWidth: 180, subtitleWidth: 190),
                  const Divider(height: 1),
                  _buildMenuItemSkeleton(shimmerColor, titleWidth: 140, subtitleWidth: 230),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 3. Shimmer Bagian 2: Keamanan Akun
            _buildSectionTitle(shimmerColor, width: 110),
            const SizedBox(height: 10),
            AccountMenuCard(
              children: [
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 160, subtitleWidth: 210),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 175, subtitleWidth: 225),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Shimmer Bagian 3: Pengaturan dan Bantuan
            _buildSectionTitle(shimmerColor, width: 160),
            const SizedBox(height: 10),
            AccountMenuCard(
              children: [
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 145, subtitleWidth: 200, hasSwitch: true),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 110, subtitleWidth: 190, hasSwitch: true),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 170, subtitleWidth: 180),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 130, subtitleWidth: 210),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 185, subtitleWidth: 200),
                const Divider(height: 1),
                _buildMenuItemSkeleton(shimmerColor, titleWidth: 175, subtitleWidth: 195),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Shimmer Tombol Keluar dari Akun
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: shimmerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: shimmerColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 110,
                      height: 14,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildHeaderSkeleton(Color shimmerColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Shimmer
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),

              // Detail Identitas Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 130,
                          height: 16,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 22,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 170,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 110,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges Shimmer
          Row(
            children: [
              Container(
                width: 100,
                height: 22,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120,
                height: 22,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 22,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(Color shimmerColor, {required double width}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMenuItemSkeleton(
    Color shimmerColor, {
    required double titleWidth,
    required double subtitleWidth,
    bool hasSwitch = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon Box Shimmer
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),

          // Text Column Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: titleWidth,
                  height: 14,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: subtitleWidth,
                  height: 11,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Trailing Action Shimmer
          if (hasSwitch)
            Container(
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            )
          else
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
