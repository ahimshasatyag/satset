import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget dasar animasi shimmer/pulse untuk skeleton loading Admin Customer Management.
class CustomerSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const CustomerSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<CustomerSkeletonBox> createState() => _CustomerSkeletonBoxState();
}

class _CustomerSkeletonBoxState extends State<CustomerSkeletonBox>
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

/// Skeleton loading lengkap untuk halaman AdminCustomerPage.
class AdminCustomerSkeleton extends StatelessWidget {
  const AdminCustomerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Skeleton Banner Header Customer Management
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
                      CustomerSkeletonBox(width: 340, height: 22),
                      SizedBox(height: 8),
                      CustomerSkeletonBox(width: 560, height: 14),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                CustomerSkeletonBox(width: 52, height: 52, borderRadius: 14),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Skeleton 4 Kartu Ringkasan Statistik Customer
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1050
                  ? 4
                  : (constraints.maxWidth > 620 ? 2 : 1);
              const spacing = 14.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (crossCount - 1))) /
                      crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(4, (index) {
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
                        CustomerSkeletonBox(
                          width: 42,
                          height: 42,
                          borderRadius: 12,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomerSkeletonBox(width: 120, height: 12),
                              SizedBox(height: 6),
                              CustomerSkeletonBox(width: 50, height: 22),
                              SizedBox(height: 4),
                              CustomerSkeletonBox(width: 95, height: 10),
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

          // 3. Skeleton Container Terpadu (Header + Filter Bar + Tabel Daftar Customer)
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
                      CustomerSkeletonBox(width: 260, height: 18),
                      SizedBox(height: 6),
                      CustomerSkeletonBox(width: 320, height: 12),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          CustomerSkeletonBox(
                            width: 290,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CustomerSkeletonBox(
                            width: 215,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CustomerSkeletonBox(
                            width: 220,
                            height: 38,
                            borderRadius: 10,
                          ),
                          CustomerSkeletonBox(
                            width: 155,
                            height: 38,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CustomerTableRowsSkeleton(rowCount: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton baris-baris tabel pada CustomerDataTable.
class CustomerTableRowsSkeleton extends StatelessWidget {
  final int rowCount;

  const CustomerTableRowsSkeleton({
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
              CustomerSkeletonBox(
                width: 38,
                height: 38,
                shape: BoxShape.circle,
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerSkeletonBox(width: 130, height: 14),
                    SizedBox(height: 6),
                    CustomerSkeletonBox(width: 85, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerSkeletonBox(width: 150, height: 13),
                    SizedBox(height: 6),
                    CustomerSkeletonBox(width: 105, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              CustomerSkeletonBox(width: 105, height: 24, borderRadius: 20),
              SizedBox(width: 18),
              CustomerSkeletonBox(width: 160, height: 14),
              SizedBox(width: 18),
              CustomerSkeletonBox(width: 110, height: 14),
              SizedBox(width: 18),
              CustomerSkeletonBox(width: 90, height: 14),
              SizedBox(width: 18),
              CustomerSkeletonBox(width: 85, height: 30, borderRadius: 8),
            ],
          ),
        );
      }),
    );
  }
}

