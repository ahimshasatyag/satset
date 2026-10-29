import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget skeleton loading placeholder untuk Halaman Daftar Alamat (AddressListPage) SatSet.
/// Menampilkan animasi shimmer realistis menyerupai search bar, filter chips, info banner,
/// dan kartu-kartu alamat pengiriman.
class AddressListSkeleton extends StatelessWidget {
  /// Jika true, menampilkan juga shimmer untuk search bar, filter bar, dan info banner.
  final bool showHeader;

  /// Jumlah kartu alamat dummy shimmer yang ditampilkan.
  final int itemCount;

  const AddressListSkeleton({
    super.key,
    this.showHeader = true,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (showHeader) ...[
          // 1. Shimmer Search Bar
          _buildSearchBarSkeleton(isDark),
          const SizedBox(height: 10),

          // 2. Shimmer Filter Chips Bar
          _buildFilterChipsSkeleton(isDark),
          const SizedBox(height: 12),

          // 3. Shimmer Info Banner
          _buildInfoBannerSkeleton(isDark),
          const SizedBox(height: 14),
        ],

        // 4. Shimmer Address Cards
        ...List.generate(
          itemCount,
          (index) => _buildAddressCardSkeleton(
            cardBg: cardBg,
            borderColor: borderColor,
            isDark: isDark,
            isFirst: index == 0,
          ),
        ),
      ],
    );
  }

  /// Shimmer Input Search Bar
  Widget _buildSearchBarSkeleton(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          CustomShimmer.circle(size: 20),
          SizedBox(width: 12),
          CustomShimmer(width: 160, height: 14),
        ],
      ),
    );
  }

  /// Shimmer Kategori Filter Chips (Semua, Utama, Lainnya)
  Widget _buildFilterChipsSkeleton(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          _buildChipSkeleton(width: 84, isSelected: true, isDark: isDark),
          const SizedBox(width: 8),
          _buildChipSkeleton(width: 96, isSelected: false, isDark: isDark),
          const SizedBox(width: 8),
          _buildChipSkeleton(width: 90, isSelected: false, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildChipSkeleton({
    required double width,
    required bool isSelected,
    required bool isDark,
  }) {
    return Container(
      height: 34,
      width: width,
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? AppColors.primary900.withValues(alpha: 0.3)
                : AppColors.primary50)
            : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      alignment: Alignment.center,
      child: CustomShimmer(
        width: width - 36,
        height: 12,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// Shimmer Banner Informasi Alamat Utama
  Widget _buildInfoBannerSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.primary50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        children: [
          CustomShimmer.circle(size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(width: double.infinity, height: 11),
                SizedBox(height: 5),
                CustomShimmer(width: 180, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Kartu Alamat Tunggal
  Widget _buildAddressCardSkeleton({
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required bool isFirst,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst
            ? (isDark
                ? AppColors.primary900.withValues(alpha: 0.25)
                : AppColors.primary50.withValues(alpha: 0.6))
            : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? AppColors.primary.withValues(alpha: 0.35)
              : borderColor,
          width: isFirst ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Ikon + Label Judul Alamat + Badge Utama
          Row(
            children: [
              const CustomShimmer.circle(size: 32),
              const SizedBox(width: 10),
              const CustomShimmer(width: 80, height: 16),
              const SizedBox(width: 8),
              if (isFirst)
                CustomShimmer(
                  width: 64,
                  height: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              const Spacer(),
              CustomShimmer(
                width: 50,
                height: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Baris Nama Penerima & Telepon
          const Row(
            children: [
              CustomShimmer.circle(size: 14),
              SizedBox(width: 6),
              CustomShimmer(width: 110, height: 13),
              SizedBox(width: 10),
              CustomShimmer(width: 90, height: 12),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Alamat Lengkap
          const CustomShimmer(width: double.infinity, height: 12),
          const SizedBox(height: 5),
          const CustomShimmer(width: 220, height: 12),
          const SizedBox(height: 10),

          // 4. Region (Kelurahan, Kecamatan, Kota, dsb.)
          const Row(
            children: [
              CustomShimmer.circle(size: 14),
              SizedBox(width: 6),
              CustomShimmer(width: 170, height: 11),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Divider
          Divider(
            height: 1,
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 10),

          // 6. Action Buttons Bar
          Row(
            children: [
              CustomShimmer(
                width: 68,
                height: 28,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 8),
              CustomShimmer(
                width: 68,
                height: 28,
                borderRadius: BorderRadius.circular(8),
              ),
              const Spacer(),
              if (!isFirst)
                CustomShimmer(
                  width: 100,
                  height: 28,
                  borderRadius: BorderRadius.circular(8),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
