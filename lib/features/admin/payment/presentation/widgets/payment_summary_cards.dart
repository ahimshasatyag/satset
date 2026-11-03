import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/admin_payment_item.dart';

class PaymentSummaryCards extends StatelessWidget {
  final AdminPaymentSummaryStats stats;
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const PaymentSummaryCards({
    super.key,
    required this.stats,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _PaymentSummaryCardItem(
        title: 'Total Transaksi Pembayaran',
        subtitle: '${stats.totalTransactions} transaksi di t_shipment_payments',
        amountText: AdminCurrencyFormatter.formatRupiah(stats.totalAmount),
        badgeText: '${stats.totalTransactions} Total',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
        isSelected: activeTab == AdminPaymentTab.all,
        onTap: () => onTabSelected(AdminPaymentTab.all),
      ),
      _PaymentSummaryCardItem(
        title: 'Pembayaran Berhasil (PAID)',
        subtitle: 'Terverifikasi lunas (Gateway & COD)',
        amountText: AdminCurrencyFormatter.formatRupiah(stats.paidAmount),
        badgeText: '${stats.paidCount} Lunas',
        icon: Icons.verified_rounded,
        color: AppColors.success,
        isSelected: activeTab == AdminPaymentTab.paid,
        onTap: () => onTabSelected(AdminPaymentTab.paid),
      ),
      _PaymentSummaryCardItem(
        title: 'Pembayaran Menunggu (PENDING)',
        subtitle: 'Menunggu pelunasan transfer / COD',
        amountText: AdminCurrencyFormatter.formatRupiah(stats.pendingAmount),
        badgeText: '${stats.pendingCount} Pending',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        isSelected: activeTab == AdminPaymentTab.pending,
        onTap: () => onTabSelected(AdminPaymentTab.pending),
      ),
      _PaymentSummaryCardItem(
        title: 'Gagal & Kedaluwarsa',
        subtitle: '${stats.failedCount} Failed • ${stats.expiredCount} Expired',
        amountText: AdminCurrencyFormatter.formatRupiah(
          stats.failedAmount + stats.expiredAmount,
        ),
        badgeText: '${stats.failedCount + stats.expiredCount} Transaksi',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        isSelected:
            activeTab == AdminPaymentTab.failed ||
            activeTab == AdminPaymentTab.expired,
        onTap: () => onTabSelected(
          stats.failedCount > 0
              ? AdminPaymentTab.failed
              : AdminPaymentTab.expired,
        ),
      ),
      _PaymentSummaryCardItem(
        title: 'COD Belum Diselesaikan',
        subtitle: 'Tagihan COD dalam proses penagihan kurir',
        amountText: AdminCurrencyFormatter.formatRupiah(
          stats.codUnsettledAmount,
        ),
        badgeText: '${stats.codUnsettledCount} Belum Lunas',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
        isSelected: activeTab == AdminPaymentTab.cod,
        onTap: () => onTabSelected(AdminPaymentTab.cod),
      ),
      _PaymentSummaryCardItem(
        title: 'COD Sudah Diselesaikan',
        subtitle:
            'Total COD: ${stats.codTotalCount} transaksi (${AdminCurrencyFormatter.formatRupiah(stats.codTotalAmount)})',
        amountText: AdminCurrencyFormatter.formatRupiah(stats.codSettledAmount),
        badgeText: '${stats.codSettledCount} COD Lunas',
        icon: Icons.handshake_rounded,
        color: AppColors.info,
        isSelected: false,
        onTap: () => onTabSelected(AdminPaymentTab.cod),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1180
            ? 3
            : (constraints.maxWidth > 680 ? 2 : 1);
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    c.badgeText,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: c.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.amountText,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

class _PaymentSummaryCardItem {
  final String title;
  final String subtitle;
  final String amountText;
  final String badgeText;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentSummaryCardItem({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.badgeText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
}
