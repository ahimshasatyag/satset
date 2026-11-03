import 'package:flutter/material.dart';

class AdminSettingsSkeleton extends StatefulWidget {
  const AdminSettingsSkeleton({super.key});

  @override
  State<AdminSettingsSkeleton> createState() => _AdminSettingsSkeletonState();
}

class _AdminSettingsSkeletonState extends State<AdminSettingsSkeleton>
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
          _box(width: 280, height: 28),
          const SizedBox(height: 8),
          _box(width: 480, height: 16),
          const SizedBox(height: 24),
          _box(height: 72),
          const SizedBox(height: 20),
          _box(height: 100),
          const SizedBox(height: 20),
          _box(height: 380),
        ],
      ),
    );
  }
}

