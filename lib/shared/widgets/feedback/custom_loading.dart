import 'package:flutter/material.dart';
import '../..//theme/theme.dart';

/// Widget indikator loading kustom dengan warna brand SatSet
class CustomLoading extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const CustomLoading({
    super.key,
    this.message,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
              backgroundColor: AppColors.primary100,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget Shimmer / Skeleton loader ringan tanpa dependensi eksternal
class CustomShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shapeBorder;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shapeBorder,
  });

  /// Pintasan skeleton lingkaran untuk avatar
  const CustomShimmer.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shapeBorder = const CircleBorder();

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final baseColor = isDark ? AppColors.surfaceVariantDark : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: widget.shapeBorder == null
                ? (widget.borderRadius ?? BorderRadius.circular(8))
                : null,
            shape: widget.shapeBorder is CircleBorder
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}
