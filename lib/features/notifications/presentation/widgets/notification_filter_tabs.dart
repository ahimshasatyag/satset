import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/notification_item.dart';

class NotificationFilterTabs extends StatelessWidget {
  final NotificationFilter activeFilter;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final bool isCourier;

  const NotificationFilterTabs({
    super.key,
    required this.activeFilter,
    required this.unreadCount,
    required this.onFilterChanged,
    this.isCourier = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = isCourier
        ? const [
            NotificationFilter.all,
            NotificationFilter.unread,
            NotificationFilter.assignment,
            NotificationFilter.urgent,
            NotificationFilter.shipment,
            NotificationFilter.system,
          ]
        : const [
            NotificationFilter.all,
            NotificationFilter.unread,
            NotificationFilter.shipment,
            NotificationFilter.payment,
            NotificationFilter.system,
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = activeFilter == filter;
          final showUnreadBadge =
              filter == NotificationFilter.unread && unreadCount > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onFilterChanged(filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (showUnreadBadge) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
