import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget skeleton loading placeholder untuk Halaman Pesanan (OrdersPage) SatSet.
/// Menampilkan efek shimmer realistis yang menyerupai tab bar, filter chips, dan kartu pengiriman.
class OrdersSkeleton extends StatelessWidget {
  /// Jika true, menampilkan juga shimmer untuk tab navigasi atas dan chips filter status.
  final bool showHeader;

  /// Jumlah kartu pesanan dummy shimmer yang ditampilkan.
  final int itemCount;

  const OrdersSkeleton({
    super.key,
    this.showHeader = false,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (showHeader) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 84),
        children: [
          // 1. Shimmer Top TabBar (Kiriman Saya vs Paket Masuk)
          _buildTopTabBarSkeleton(isDark),

          // 2. Shimmer Filter Chips Bar
          _buildFilterChipsSkeleton(isDark),

          // 3. Shimmer Cards
          const SizedBox(height: 4),
          ...List.generate(
            itemCount,
            (index) => _buildOrderCardSkeleton(cardBg, borderColor, isDark),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 84),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, index) =>
          _buildOrderCardSkeleton(cardBg, borderColor, isDark),
    );
  }

  /// Shimmer untuk Tab Navigasi Atas (Kiriman Saya / Paket Masuk)
  Widget _buildTopTabBarSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomShimmer.circle(size: 18),
                  SizedBox(width: 8),
                  CustomShimmer(width: 85, height: 13),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomShimmer.circle(size: 18),
                  SizedBox(width: 8),
                  CustomShimmer(width: 80, height: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer untuk Horizontal Filter Chips Bar
  Widget _buildFilterChipsSkeleton(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          final widths = [70.0, 140.0, 130.0, 110.0];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomShimmer.circle(size: 15),
                  const SizedBox(width: 8),
                  CustomShimmer(width: widths[index % widths.length], height: 12),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Shimmer kartu pengiriman pesanan yang presisi dengan [OrderShipmentCard]
  Widget _buildOrderCardSkeleton(
      Color cardBg, Color borderColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Resi Pill, Service Type & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomShimmer(
                      width: 115,
                      height: 22,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 8),
                    const CustomShimmer(width: 55, height: 14),
                  ],
                ),
                CustomShimmer(
                  width: 84,
                  height: 24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 2: Nama Barang & Estimasi Harga
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(width: 160, height: 18),
                CustomShimmer(width: 85, height: 18),
              ],
            ),
            const SizedBox(height: 10),

            // Baris 3: Rute Kota Asal -> Kota Tujuan
            const Row(
              children: [
                CustomShimmer.circle(size: 16),
                SizedBox(width: 6),
                CustomShimmer(width: 190, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // Divider Pemisah
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),

            // Baris 4 (Footer): Icon/ETA & Tombol Aksi Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CustomShimmer.circle(size: 16),
                    SizedBox(width: 6),
                    CustomShimmer(width: 90, height: 14),
                  ],
                ),
                CustomShimmer(
                  width: 105,
                  height: 30,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
