import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/courier_task_history_stats.dart';

/// Widget ringkasan metrik statistik riwayat tugas kurir
class CourierTaskHistoryStatsHeader extends StatelessWidget {
  final CourierTaskHistoryStats stats;
  final VoidCallback? onTotalTap;
  final VoidCallback? onCompletedTap;
  final VoidCallback? onFailedTap;
  final VoidCallback? onReturnedTap;

  const CourierTaskHistoryStatsHeader({
    super.key,
    required this.stats,
    this.onTotalTap,
    this.onCompletedTap,
    this.onFailedTap,
    this.onReturnedTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            context: context,
            label: 'Total',
            value: stats.totalCount.toString(),
            color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            icon: Icons.assignment_outlined,
            onTap: onTotalTap,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            context: context,
            label: 'Selesai',
            value: stats.completedCount.toString(),
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
            onTap: onCompletedTap,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            context: context,
            label: 'Gagal',
            value: stats.failedCount.toString(),
            color: AppColors.error,
            icon: Icons.error_outline_rounded,
            onTap: onFailedTap,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            context: context,
            label: 'Kembali',
            value: stats.returnedCount.toString(),
            color: AppColors.warning,
            icon: Icons.replay_rounded,
            onTap: onReturnedTap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
