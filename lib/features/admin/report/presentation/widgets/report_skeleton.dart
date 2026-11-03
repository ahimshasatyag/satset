import 'package:flutter/material.dart';

class AdminReportSkeleton extends StatefulWidget {
  const AdminReportSkeleton({super.key});

  @override
  State<AdminReportSkeleton> createState() => _AdminReportSkeletonState();
}

class _AdminReportSkeletonState extends State<AdminReportSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    double width = double.infinity,
    required double height,
    double radius = 12,
  }) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(_controller),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _box(width: 320, height: 28),
          const SizedBox(height: 8),
          _box(width: 520, height: 18),
          const SizedBox(height: 20),
          _box(height: 110),
          const SizedBox(height: 16),
          _box(height: 120),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              6,
              (_) => _box(width: 340, height: 96),
            ),
          ),
          const SizedBox(height: 16),
          _box(height: 220),
          const SizedBox(height: 16),
          _box(height: 360),
        ],
      ),
    );
  }
}

