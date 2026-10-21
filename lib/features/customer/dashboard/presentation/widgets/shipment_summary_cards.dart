import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/shipment.dart';

class ShipmentSummaryCards extends StatelessWidget {
  final ShipmentStatusSummary summary;
  final String? activeFilter;
  final ValueChanged<String?> onFilterSelected;

  const ShipmentSummaryCards({
    super.key,
    required this.summary,
    this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _SummaryItem(
        key: 'waiting',
        title: 'Menunggu Konfirmasi',
        count: summary.waitingConfirmationCount,
        icon: Icons.hourglass_top_rounded,
        color: AppColors.secondary,
      ),
      _SummaryItem(
        key: 'process',
        title: 'Sedang Diproses',
        count: summary.inProcessCount,
        icon: Icons.inventory_2_rounded,
        color: AppColors.tertiary,
      ),
      _SummaryItem(
        key: 'transit',
        title: 'Dalam Perjalanan',
        count: summary.inTransitCount,
        icon: Icons.local_shipping_rounded,
        color: AppColors.primary,
      ),
      _SummaryItem(
        key: 'delivered',
        title: 'Telah Terkirim',
        count: summary.deliveredCount,
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Pengiriman',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              if (activeFilter != null)
                TextButton(
                  onPressed: () => onFilterSelected(null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                Text(
                  'Berdasarkan Akun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.map((item) {
              final isSelected = activeFilter == item.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        onFilterSelected(null);
                      } else {
                        onFilterSelected(item.key);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? item.color
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? item.color.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.count}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isSelected
                                  ? item.color
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String key;
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
}
