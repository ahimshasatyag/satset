import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget dasar animasi shimmer/pulse untuk skeleton loading Admin Courier Management.
class CourierSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const CourierSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<CourierSkeletonBox> createState() => _CourierSkeletonBoxState();
}

class _CourierSkeletonBoxState extends State<CourierSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.borderLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
          ),
        );
      },
    );
  }
}

/// Skeleton loading lengkap untuk halaman AdminCourierPage.
class AdminCourierSkeleton extends StatelessWidget {
  const AdminCourierSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Skeleton Banner Header Courier Management
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CourierSkeletonBox(width: 340, height: 22),
                      SizedBox(height: 8),
                      CourierSkeletonBox(width: 560, height: 14),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                CourierSkeletonBox(width: 52, height: 52, borderRadius: 14),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Skeleton 5 Kartu Ringkasan Statistik Kurir
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1200
                  ? 5
                  : (constraints.maxWidth > 760 ? 3 : 1);
              const spacing = 14.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (crossCount - 1))) /
                      crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(5, (index) {
                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: const Row(
                      children: [
                        CourierSkeletonBox(
                          width: 42,
                          height: 42,
                          borderRadius: 12,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CourierSkeletonBox(width: 110, height: 12),
                              SizedBox(height: 6),
                              CourierSkeletonBox(width: 50, height: 22),
                              SizedBox(height: 4),
                              CourierSkeletonBox(width: 90, height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),

          // 3. Skeleton Container Terpadu (Header + Tombol Tambah + Filter + Tabel Daftar Kurir)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CourierSkeletonBox(width: 260, height: 18),
                              SizedBox(height: 6),
                              CourierSkeletonBox(width: 320, height: 12),
                            ],
                          ),
                          CourierSkeletonBox(
                            width: 170,
                            height: 38,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          CourierSkeletonBox(
                            width: 290,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CourierSkeletonBox(
                            width: 195,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CourierSkeletonBox(
                            width: 225,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CourierSkeletonBox(
                            width: 215,
                            height: 38,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CourierTableRowsSkeleton(rowCount: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton baris-baris tabel pada CourierDataTable.
class CourierTableRowsSkeleton extends StatelessWidget {
  final int rowCount;

  const CourierTableRowsSkeleton({
    super.key,
    this.rowCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(rowCount, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: const Row(
            children: [
              CourierSkeletonBox(
                width: 40,
                height: 40,
                shape: BoxShape.circle,
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CourierSkeletonBox(width: 130, height: 14),
                    SizedBox(height: 6),
                    CourierSkeletonBox(width: 85, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CourierSkeletonBox(width: 150, height: 13),
                    SizedBox(height: 6),
                    CourierSkeletonBox(width: 105, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 16),
              CourierSkeletonBox(width: 85, height: 24, borderRadius: 20),
              SizedBox(width: 18),
              CourierSkeletonBox(width: 125, height: 24, borderRadius: 20),
              SizedBox(width: 18),
              CourierSkeletonBox(width: 100, height: 14),
              SizedBox(width: 18),
              CourierSkeletonBox(width: 90, height: 14),
              SizedBox(width: 18),
              CourierSkeletonBox(width: 95, height: 30, borderRadius: 8),
            ],
          ),
        );
      }),
    );
  }
}

