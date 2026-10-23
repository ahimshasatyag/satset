import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class CourierTasksSkeleton extends StatefulWidget {
  /// Jika true, menampilkan juga shimmer untuk search box, tab status tugas, dan chip kategori
  final bool showHeader;

  /// Jumlah kartu tugas placeholder yang ditampilkan
  final int itemCount;

  /// Scroll physics opsional
  final ScrollPhysics? physics;

  const CourierTasksSkeleton({
    super.key,
    this.showHeader = false,
    this.itemCount = 4,
    this.physics,
  });

  /// Constructor khusus untuk hanya menampilkan daftar kartu tugas
  const CourierTasksSkeleton.cardsOnly({
    super.key,
    this.itemCount = 4,
    this.physics,
  }) : showHeader = false;

  /// Constructor untuk menampilkan halaman penuh beserta header shimmer
  const CourierTasksSkeleton.fullPage({
    super.key,
    this.itemCount = 4,
    this.physics,
  }) : showHeader = true;

  @override
  State<CourierTasksSkeleton> createState() => _CourierTasksSkeletonState();
}

class _CourierTasksSkeletonState extends State<CourierTasksSkeleton>
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
    final baseColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = baseColor.withValues(alpha: _animation.value);

        if (widget.showHeader) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
            children: [
              // 1. Shimmer Search Box
              _buildShimmerBox(
                width: double.infinity,
                height: 44,
                radius: 12,
                color: shimmerColor,
              ),
              const SizedBox(height: 12),

              // 2. Shimmer Filter Tabs (Perlu Dikerjakan, Berlangsung, Selesai)
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      height: 42,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Shimmer Filter Chips (Semua Tugas, Pickup, Delivery)
              Row(
                children: [
                  _buildShimmerBox(
                    width: 80,
                    height: 32,
                    radius: 20,
                    color: shimmerColor,
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(
                    width: 120,
                    height: 32,
                    radius: 20,
                    color: shimmerColor,
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(
                    width: 120,
                    height: 32,
                    radius: 20,
                    color: shimmerColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Shimmer Courier Task Cards
              ...List.generate(
                widget.itemCount,
                (index) => CourierTaskCardSkeleton(
                  shimmerColor: shimmerColor,
                  isDark: isDark,
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return CourierTaskCardSkeleton(
              shimmerColor: shimmerColor,
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Widget kartu satuan placeholder menyerupai [CourierTaskCard]
class CourierTaskCardSkeleton extends StatelessWidget {
  final Color shimmerColor;
  final bool isDark;

  const CourierTaskCardSkeleton({
    super.key,
    required this.shimmerColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Baris Atas: Tipe Tugas (Pickup/Delivery) & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBox(width: 85, height: 26, radius: 8),
              _buildBox(width: 80, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Baris Resi & Tipe Layanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBox(width: 140, height: 16, radius: 4),
                  const SizedBox(width: 8),
                  _buildBox(width: 16, height: 16, radius: 4),
                ],
              ),
              _buildBox(width: 65, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Nama Pihak Penerima/Pengirim
          Row(
            children: [
              _buildBox(width: 16, height: 16, radius: 8),
              const SizedBox(width: 8),
              _buildBox(width: 180, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 8),

          // 4. Alamat Tujuan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBox(width: 16, height: 16, radius: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBox(width: double.infinity, height: 12, radius: 4),
                    const SizedBox(height: 6),
                    _buildBox(width: 160, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),

          // 5. Informasi Berat / Estimasi & Tombol Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBox(width: 70, height: 12, radius: 4),
                  const SizedBox(height: 4),
                  _buildBox(width: 95, height: 12, radius: 4),
                ],
              ),
              _buildBox(width: 105, height: 34, radius: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
