import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';

class PaymentSummaryCard extends StatelessWidget {
  final AdminPaymentSummary paymentSummary;

  const PaymentSummaryCard({super.key, required this.paymentSummary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Transaksi Pembayaran',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Data transaksi pembayaran dari t_shipment_payments',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),

          // Total Omset / Perputaran Dana
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary50.withValues(alpha: isDark ? 0.08 : 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Nilai Transaksi',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AdminCurrencyFormatter.formatRupiah(paymentSummary.totalAmount),
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${paymentSummary.totalCount} Transaksi',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Kolom Status Pembayaran: Lunas, Menunggu, COD
          Row(
            children: [
              // Lunas
              Expanded(
                child: _PaymentItem(
                  title: 'Lunas / Berhasil',
                  amount: paymentSummary.paidAmount,
                  count: paymentSummary.paidCount,
                  color: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              // Menunggu
              Expanded(
                child: _PaymentItem(
                  title: 'Menunggu Bayar',
                  amount: paymentSummary.pendingAmount,
                  count: paymentSummary.pendingCount,
                  color: AppColors.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
              ),
              const SizedBox(width: 12),
              // COD
              Expanded(
                child: _PaymentItem(
                  title: 'Metode COD',
                  amount: paymentSummary.codAmount,
                  count: paymentSummary.codCount,
                  color: AppColors.secondary,
                  icon: Icons.handshake_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String title;
  final num amount;
  final int count;
  final Color color;
  final IconData icon;

  const _PaymentItem({
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AdminCurrencyFormatter.formatRupiah(amount),
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$count transaksi',
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

