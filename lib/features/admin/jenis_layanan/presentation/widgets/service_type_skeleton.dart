import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class AdminServiceTypeSkeleton extends StatefulWidget {
  const AdminServiceTypeSkeleton({super.key});

  @override
  State<AdminServiceTypeSkeleton> createState() =>
      _AdminServiceTypeSkeletonState();
}

class _AdminServiceTypeSkeletonState extends State<AdminServiceTypeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    double? width,
    required double height,
    double radius = 10,
    required bool isDark,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(_controller),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _box(height: 88, radius: 16, isDark: isDark),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              4,
              (_) => SizedBox(
                width: 260,
                child: _box(height: 92, radius: 14, isDark: isDark),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const ServiceTypeTableRowsSkeleton(rowCount: 5),
          ),
        ],
      ),
    );
  }
}

class ServiceTypeTableRowsSkeleton extends StatefulWidget {
  final int rowCount;

  const ServiceTypeTableRowsSkeleton({super.key, this.rowCount = 5});

  @override
  State<ServiceTypeTableRowsSkeleton> createState() =>
      _ServiceTypeTableRowsSkeletonState();
}

class _ServiceTypeTableRowsSkeletonState
    extends State<ServiceTypeTableRowsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBar({
    required double width,
    required double height,
    required bool isDark,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(_controller),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(widget.rowCount, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              _shimmerBar(width: 90, height: 18, isDark: isDark),
              const SizedBox(width: 20),
              Expanded(
                child: _shimmerBar(width: 180, height: 18, isDark: isDark),
              ),
              const SizedBox(width: 20),
              _shimmerBar(width: 120, height: 22, isDark: isDark),
              const SizedBox(width: 20),
              _shimmerBar(width: 110, height: 22, isDark: isDark),
              const SizedBox(width: 20),
              _shimmerBar(width: 90, height: 24, isDark: isDark),
              const SizedBox(width: 20),
              _shimmerBar(width: 90, height: 28, isDark: isDark),
            ],
          ),
        );
      }),
    );
  }
}

