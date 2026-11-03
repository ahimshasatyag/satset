import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_item.dart';

class PaymentStatusTabs extends StatelessWidget {
  final String activeTab;
  final Map<String, int> tabCounts;
  final ValueChanged<String> onTabSelected;

  const PaymentStatusTabs({
    super.key,
    required this.activeTab,
    required this.tabCounts,
    required this.onTabSelected,
  });

  static const List<Map<String, dynamic>> _tabs = [
    {
      'key': AdminPaymentTab.all,
      'label': 'Semua Transaksi',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'key': AdminPaymentTab.pending,
      'label': 'Pending / Menunggu',
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'key': AdminPaymentTab.paid,
      'label': 'Paid / Lunas',
      'icon': Icons.verified_rounded,
    },
    {
      'key': AdminPaymentTab.failed,
      'label': 'Failed / Gagal',
      'icon': Icons.cancel_outlined,
    },
    {
      'key': AdminPaymentTab.expired,
      'label': 'Expired / Kedaluwarsa',
      'icon': Icons.timer_off_outlined,
    },
    {
      'key': AdminPaymentTab.cod,
      'label': 'Transaksi COD',
      'icon': Icons.handshake_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: _tabs.map((tab) {
              final key = tab['key'] as String;
              final label = tab['label'] as String;
              final icon = tab['icon'] as IconData;
              final count = tabCounts[key] ?? 0;
              final isSelected = activeTab == key;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onTabSelected(key),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(10),
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
                        Icon(
                          icon,
                          size: 16,
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
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.22)
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

