import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackFilterBar extends StatelessWidget {
  final OrderFilterStatus selectedStatus;
  final ValueChanged<OrderFilterStatus> onStatusSelected;
  final Map<OrderFilterStatus, int>? counts;

  const LiveTrackFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      {
        'status': OrderFilterStatus.all,
        'label': 'Semua',
        'icon': Icons.tune_rounded,
      },
      {
        'status': OrderFilterStatus.waitingPickup,
        'label': 'Menunggu Pickup',
        'icon': Icons.schedule_rounded,
      },
      {
        'status': OrderFilterStatus.inDelivery,
        'label': 'Sedang Diantar',
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'status': OrderFilterStatus.completed,
        'label': 'Selesai',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: filters.map((item) {
          final status = item['status'] as OrderFilterStatus;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selectedStatus == status;
          final count = counts?[status];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.tertiary50,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onStatusSelected(status),
            ),
          );
        }).toList(),
      ),
    );
  }
}
