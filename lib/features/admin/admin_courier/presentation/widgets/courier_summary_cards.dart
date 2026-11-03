import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_courier_item.dart';

class CourierSummaryCards extends StatelessWidget {
  final AdminCourierSummaryStats stats;
  final String activeAccountFilter;
  final String activeActivityFilter;
  final void Function({
    String? accountStatusFilter,
    String? activityStatusFilter,
  }) onQuickFilterSelected;

  const CourierSummaryCards({
    super.key,
    required this.stats,
    required this.activeAccountFilter,
    required this.activeActivityFilter,
    required this.onQuickFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _SummaryItem(
        title: 'Seluruh Kurir Terdaftar',
        subtitle: 'm_employee (id_users_role = 2)',
        count: stats.totalCouriers,
        icon: Icons.two_wheeler_rounded,
        color: AppColors.primary,
        isSelected:
            activeAccountFilter == 'ALL' && activeActivityFilter == 'ALL',
        onTap: () => onQuickFilterSelected(
          accountStatusFilter: 'ALL',
          activityStatusFilter: 'ALL',
        ),
      ),
      _SummaryItem(
        title: 'Kurir Akun Aktif',
        subtitle: 'is_active = true',
        count: stats.activeCouriers,
        icon: Icons.verified_user_rounded,
        color: AppColors.success,
        isSelected: activeAccountFilter == 'ACTIVE',
        onTap: () => onQuickFilterSelected(
          accountStatusFilter: 'ACTIVE',
          activityStatusFilter: 'ALL',
        ),
      ),
      _SummaryItem(
        title: 'Kurir Tidak Aktif',
        subtitle: 'is_active = false',
        count: stats.inactiveCouriers,
        icon: Icons.person_off_rounded,
        color: AppColors.error,
        isSelected: activeAccountFilter == 'INACTIVE',
        onTap: () => onQuickFilterSelected(
          accountStatusFilter: 'INACTIVE',
          activityStatusFilter: 'ALL',
        ),
      ),
      _SummaryItem(
        title: 'Sedang Memiliki Tugas',
        subtitle: 'Penugasan aktif di t_shipment_assignments',
        count: stats.couriersWithActiveTask,
        icon: Icons.local_shipping_rounded,
        color: AppColors.secondary,
        isSelected: activeActivityFilter == 'ON_TASK',
        onTap: () => onQuickFilterSelected(
          accountStatusFilter: 'ALL',
          activityStatusFilter: 'ON_TASK',
        ),
      ),
      _SummaryItem(
        title: 'Belum Memiliki Penugasan',
        subtitle: 'Siap menerima tugas pengiriman',
        count: stats.couriersWithoutActiveTask,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.tertiary,
        isSelected: activeActivityFilter == 'UNASSIGNED',
        onTap: () => onQuickFilterSelected(
          accountStatusFilter: 'ALL',
          activityStatusFilter: 'UNASSIGNED',
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 5
            : (constraints.maxWidth > 760 ? 3 : 1);
        const spacing = 14.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) {
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: c.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.isSelected
                          ? c.color
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      width: c.isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(c.icon, color: c.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.count}',
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: c.color,
                              ),
                            ),
                            Text(
                              c.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryItem {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryItem({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
}

