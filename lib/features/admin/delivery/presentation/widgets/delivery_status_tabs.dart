import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_delivery_item.dart';

class DeliveryStatusTabs extends StatelessWidget {
  final String activeTab;
  final Map<String, int> tabCounts;
  final ValueChanged<String> onTabSelected;

  const DeliveryStatusTabs({
    super.key,
    required this.activeTab,
    required this.tabCounts,
    required this.onTabSelected,
  });

  IconData _getIconForTab(String key) {
    switch (key) {
      case AdminDeliveryTab.waitingConfirmation:
        return Icons.pending_actions_rounded;
      case AdminDeliveryTab.waitingAssignment:
        return Icons.person_add_alt_1_rounded;
      case AdminDeliveryTab.inProcess:
        return Icons.inventory_2_rounded;
      case AdminDeliveryTab.outForDelivery:
        return Icons.local_shipping_rounded;
      case AdminDeliveryTab.delivered:
        return Icons.check_circle_rounded;
      case AdminDeliveryTab.failed:
        return Icons.warning_amber_rounded;
      case AdminDeliveryTab.cancelled:
        return Icons.cancel_rounded;
      case AdminDeliveryTab.all:
      default:
        return Icons.all_inbox_rounded;
    }
  }

  Color _getAccentColorForTab(String key) {
    switch (key) {
      case AdminDeliveryTab.waitingConfirmation:
      case AdminDeliveryTab.waitingAssignment:
        return AppColors.warning;
      case AdminDeliveryTab.inProcess:
      case AdminDeliveryTab.outForDelivery:
        return AppColors.info;
      case AdminDeliveryTab.delivered:
        return AppColors.success;
      case AdminDeliveryTab.failed:
      case AdminDeliveryTab.cancelled:
        return AppColors.error;
      case AdminDeliveryTab.all:
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan Kartu Status Utama
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final summaryTabs = [
              AdminDeliveryTab.all,
              AdminDeliveryTab.waitingConfirmation,
              AdminDeliveryTab.waitingAssignment,
              AdminDeliveryTab.inProcess,
              AdminDeliveryTab.outForDelivery,
              AdminDeliveryTab.delivered,
              AdminDeliveryTab.failed,
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: summaryTabs.map((tabKey) {
                final tabMeta = AdminDeliveryTab.tabs.firstWhere(
                  (t) => t['key'] == tabKey,
                  orElse: () => {'key': tabKey, 'label': tabKey},
                );
                final count = tabCounts[tabKey] ?? 0;
                final isSelected = activeTab == tabKey;
                final accent = _getAccentColorForTab(tabKey);
                final cardWidth = isWide
                    ? (constraints.maxWidth - (12 * 6)) / 7
                    : (constraints.maxWidth - 12) / 2;

                return SizedBox(
                  width: cardWidth.clamp(135.0, 260.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onTabSelected(tabKey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? AppColors.surfaceDark : AppColors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                      alpha: isDark ? 0.25 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIconForTab(tabKey),
                                    size: 16,
                                    color: accent,
                                  ),
                                ),
                                Text(
                                  '$count',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? accent
                                        : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tabMeta['label'] ?? tabKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? accent
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),

        // Bar Tab Pengelompokan Status
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AdminDeliveryTab.tabs.map((tab) {
                  final key = tab['key']!;
                  final label = tab['label']!;
                  final count = tabCounts[key] ?? 0;
                  final isSelected = activeTab == key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onTabSelected(key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForTab(key),
                                size: 15,
                                color: isSelected
                                    ? AppColors.white
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.white
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.white.withValues(alpha: 0.22)
                                      : (isDark
                                          ? AppColors.backgroundDark
                                          : AppColors.backgroundLight),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

