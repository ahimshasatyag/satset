import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_dashboard_stats.dart';

class ShipmentTrendChart extends StatelessWidget {
  final List<AdminTrendPoint> dailyTrends;
  final List<AdminTrendPoint> weeklyTrends;
  final List<AdminTrendPoint> monthlyTrends;
  final String activePeriod; // 'DAILY', 'WEEKLY', 'MONTHLY'
  final ValueChanged<String> onPeriodChanged;

  const ShipmentTrendChart({
    super.key,
    required this.dailyTrends,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.activePeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final points = activePeriod == 'DAILY'
        ? dailyTrends
        : (activePeriod == 'WEEKLY' ? weeklyTrends : monthlyTrends);

    final maxVal = points.isEmpty
        ? 10
        : points.map((p) => math.max(p.total, math.max(p.delivered, p.failed))).fold<int>(0, math.max);
    final chartMax = maxVal == 0 ? 5 : (maxVal * 1.2).ceil();

    return Container(
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
          // Header & Period Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Pengiriman & Performa',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perbandingan total, berhasil, dan gagal kirim',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodButton(
                      label: 'Harian',
                      isSelected: activePeriod == 'DAILY',
                      onTap: () => onPeriodChanged('DAILY'),
                    ),
                    _PeriodButton(
                      label: 'Mingguan',
                      isSelected: activePeriod == 'WEEKLY',
                      onTap: () => onPeriodChanged('WEEKLY'),
                    ),
                    _PeriodButton(
                      label: 'Bulanan',
                      isSelected: activePeriod == 'MONTHLY',
                      onTap: () => onPeriodChanged('MONTHLY'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            children: [
              _LegendItem(color: AppColors.primary, label: 'Total Pengiriman'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.success, label: 'Berhasil'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.error, label: 'Gagal / Dibatalkan'),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Bar Chart Area
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Belum ada data pengiriman pada periode ini.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Bar Total
                                _Bar(
                                  value: p.total,
                                  max: chartMax,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3),
                                // Bar Berhasil
                                _Bar(
                                  value: p.delivered,
                                  max: chartMax,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 3),
                                // Bar Gagal
                                _Bar(
                                  value: p.failed,
                                  max: chartMax,
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;

  const _Bar({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final heightRatio = max > 0 ? (value / max).clamp(0.04, 1.0) : 0.04;

    return Tooltip(
      message: '$value paket',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight * heightRatio;
          return Container(
            width: 10,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

