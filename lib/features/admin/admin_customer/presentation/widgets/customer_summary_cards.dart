import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_customer_item.dart';

class CustomerSummaryCards extends StatelessWidget {
  final AdminCustomerSummaryStats stats;
  final String activeVerificationFilter;
  final ValueChanged<String> onQuickFilterSelected;

  const CustomerSummaryCards({
    super.key,
    required this.stats,
    required this.activeVerificationFilter,
    required this.onQuickFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _SummaryItem(
        title: 'Seluruh Customer Terdaftar',
        subtitle: 'm_users (id_users_role = 3)',
        count: stats.totalCustomers,
        icon: Icons.people_alt_rounded,
        color: AppColors.primary,
        isSelected: activeVerificationFilter == 'ALL',
        onTap: () => onQuickFilterSelected('ALL'),
      ),
      _SummaryItem(
        title: 'Customer Terverifikasi',
        subtitle: 'email_verified = true',
        count: stats.verifiedCustomers,
        icon: Icons.verified_rounded,
        color: AppColors.success,
        isSelected: activeVerificationFilter == 'VERIFIED',
        onTap: () => onQuickFilterSelected('VERIFIED'),
      ),
      _SummaryItem(
        title: 'Belum Terverifikasi',
        subtitle: 'email_verified = false',
        count: stats.unverifiedCustomers,
        icon: Icons.mark_email_unread_rounded,
        color: AppColors.warning,
        isSelected: activeVerificationFilter == 'UNVERIFIED',
        onTap: () => onQuickFilterSelected('UNVERIFIED'),
      ),
      _SummaryItem(
        title: 'Customer Baru (30 Hari)',
        subtitle: 'Registrasi dalam 30 hari terakhir',
        count: stats.newCustomersThisMonth,
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.secondary,
        isSelected: activeVerificationFilter == 'NEW_30_DAYS',
        onTap: () => onQuickFilterSelected('NEW_30_DAYS'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1050
            ? 4
            : (constraints.maxWidth > 620 ? 2 : 1);
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

