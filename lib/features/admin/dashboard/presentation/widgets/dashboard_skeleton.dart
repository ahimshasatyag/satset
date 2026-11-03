import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget dasar animasi shimmer/pulse untuk skeleton loading Dashboard Admin.
class DashboardSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const DashboardSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<DashboardSkeletonBox> createState() => _DashboardSkeletonBoxState();
}

class _DashboardSkeletonBoxState extends State<DashboardSkeletonBox>
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

/// Skeleton loading lengkap untuk konten utama halaman AdminDashboardPage.
class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Skeleton Banner Header Dashboard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      DashboardSkeletonBox(width: 280, height: 24),
                      SizedBox(height: 10),
                      DashboardSkeletonBox(width: 520, height: 14),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                DashboardSkeletonBox(width: 56, height: 56, borderRadius: 14),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Skeleton Statistics Cards (8 Kartu Statistik)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : (constraints.maxWidth > 650 ? 2 : 1);
              final spacing = 16.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(8, (index) {
                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: const Row(
                      children: [
                        DashboardSkeletonBox(
                          width: 46,
                          height: 46,
                          borderRadius: 12,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardSkeletonBox(width: 90, height: 12),
                              SizedBox(height: 8),
                              DashboardSkeletonBox(width: 60, height: 22),
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
          const SizedBox(height: 24),

          // 3. Skeleton Charts Section (Trend Chart + Status Distribution Chart)
          LayoutBuilder(
            builder: (context, constraints) {
              final trendSkeleton = Container(
                height: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DashboardSkeletonBox(width: 180, height: 18),
                            SizedBox(height: 6),
                            DashboardSkeletonBox(width: 240, height: 12),
                          ],
                        ),
                        DashboardSkeletonBox(
                          width: 160,
                          height: 32,
                          borderRadius: 8,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: DashboardSkeletonBox(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 12,
                      ),
                    ),
                  ],
                ),
              );

              final statusSkeleton = Container(
                height: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardSkeletonBox(width: 170, height: 18),
                    SizedBox(height: 6),
                    DashboardSkeletonBox(width: 210, height: 12),
                    SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: DashboardSkeletonBox(
                          width: 150,
                          height: 150,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth > 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: trendSkeleton),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: statusSkeleton),
                  ],
                );
              }
              return Column(
                children: [
                  trendSkeleton,
                  const SizedBox(height: 20),
                  statusSkeleton,
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. Skeleton Summaries Section (Payment Summary + Courier Summary)
          LayoutBuilder(
            builder: (context, constraints) {
              Widget buildSummaryCardSkeleton() {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardSkeletonBox(width: 190, height: 18),
                      const SizedBox(height: 6),
                      const DashboardSkeletonBox(width: 240, height: 12),
                      const SizedBox(height: 18),
                      ...List.generate(3, (index) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: DashboardSkeletonBox(
                            width: double.infinity,
                            height: 46,
                            borderRadius: 10,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }

              if (constraints.maxWidth > 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildSummaryCardSkeleton()),
                    const SizedBox(width: 20),
                    Expanded(child: buildSummaryCardSkeleton()),
                  ],
                );
              }
              return Column(
                children: [
                  buildSummaryCardSkeleton(),
                  const SizedBox(height: 20),
                  buildSummaryCardSkeleton(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 5. Skeleton Tabel Pengiriman Terbaru
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
                      DashboardSkeletonBox(width: 200, height: 18),
                      SizedBox(height: 6),
                      DashboardSkeletonBox(width: 300, height: 12),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          DashboardSkeletonBox(
                            width: 260,
                            height: 38,
                            borderRadius: 10,
                          ),
                          DashboardSkeletonBox(
                            width: 215,
                            height: 38,
                            borderRadius: 10,
                          ),
                          DashboardSkeletonBox(
                            width: 195,
                            height: 38,
                            borderRadius: 10,
                          ),
                          DashboardSkeletonBox(
                            width: 140,
                            height: 38,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DashboardTableRowsSkeleton(rowCount: 5),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. Skeleton Aktivitas Terbaru
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardSkeletonBox(width: 210, height: 18),
                const SizedBox(height: 16),
                ...List.generate(4, (index) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        DashboardSkeletonBox(
                          width: 36,
                          height: 36,
                          shape: BoxShape.circle,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardSkeletonBox(width: 260, height: 14),
                              SizedBox(height: 6),
                              DashboardSkeletonBox(width: 180, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton baris-baris tabel untuk RecentShipmentsTable saat sedang memuat ulang data.
class DashboardTableRowsSkeleton extends StatelessWidget {
  final int rowCount;

  const DashboardTableRowsSkeleton({
    super.key,
    this.rowCount = 5,
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
              DashboardSkeletonBox(width: 135, height: 16),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardSkeletonBox(width: 100, height: 14),
                    SizedBox(height: 6),
                    DashboardSkeletonBox(width: 130, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardSkeletonBox(width: 100, height: 14),
                    SizedBox(height: 6),
                    DashboardSkeletonBox(width: 130, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              DashboardSkeletonBox(width: 75, height: 24, borderRadius: 8),
              SizedBox(width: 24),
              DashboardSkeletonBox(width: 110, height: 14),
              SizedBox(width: 24),
              DashboardSkeletonBox(width: 115, height: 26, borderRadius: 20),
              SizedBox(width: 24),
              DashboardSkeletonBox(width: 85, height: 16),
              SizedBox(width: 24),
              DashboardSkeletonBox(width: 70, height: 30, borderRadius: 8),
            ],
          ),
        );
      }),
    );
  }
}

