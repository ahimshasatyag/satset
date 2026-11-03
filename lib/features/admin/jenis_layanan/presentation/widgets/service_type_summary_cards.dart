import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_service_type_item.dart';

class ServiceTypeSummaryCards extends StatelessWidget {
  final AdminServiceTypeSummaryStats stats;
  final String activeFilter;
  final ValueChanged<String> onQuickFilterSelected;

  const ServiceTypeSummaryCards({
    super.key,
    required this.stats,
    required this.activeFilter,
    required this.onQuickFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _SummaryCardData(
        title: 'Seluruh Jenis Layanan',
        subtitle: 'Master m_service_types terdaftar',
        countText: '${stats.totalServices} Layanan',
        badgeText: 'Total',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
        isSelected: activeFilter == 'ALL',
        onTap: () => onQuickFilterSelected('ALL'),
      ),
      _SummaryCardData(
        title: 'Layanan Aktif',
        subtitle: 'Tersedia pada form pemesanan customer',
        countText: '${stats.activeServices} Aktif',
        badgeText: 'is_active = true',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        isSelected: activeFilter == 'ACTIVE',
        onTap: () => onQuickFilterSelected('ACTIVE'),
      ),
      _SummaryCardData(
        title: 'Layanan Tidak Aktif',
        subtitle: 'Nonaktif untuk pesanan baru, histori tetap aman',
        countText: '${stats.inactiveServices} Nonaktif',
        badgeText: 'is_active = false',
        icon: Icons.pause_circle_outline_rounded,
        color: AppColors.warning,
        isSelected: activeFilter == 'INACTIVE',
        onTap: () => onQuickFilterSelected('INACTIVE'),
      ),
      _SummaryCardData(
        title: 'Digunakan pada Pengiriman',
        subtitle:
            '${stats.totalShipmentsUsingServices} pengiriman (${AdminCurrencyFormatter.formatCompactRupiah(stats.totalRevenueFromServices)})',
        countText: '${stats.usedServicesCount} Layanan',
        badgeText: 'Relasi t_shipments',
        icon: Icons.local_shipping_outlined,
        color: AppColors.info,
        isSelected: activeFilter == 'USED',
        onTap: () => onQuickFilterSelected('USED'),
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
                      width: c.isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(c.icon, color: c.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    c.badgeText,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: c.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.countText,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.subtitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

class _SummaryCardData {
  final String title;
  final String subtitle;
  final String countText;
  final String badgeText;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCardData({
    required this.title,
    required this.subtitle,
    required this.countText,
    required this.badgeText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
}

