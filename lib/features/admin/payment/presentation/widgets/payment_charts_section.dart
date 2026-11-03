import 'dart:math';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_item.dart';

class PaymentChartsSection extends StatelessWidget {
  final AdminPaymentSummaryStats stats;
  final AdminPaymentPeriod selectedPeriod;
  final ValueChanged<AdminPaymentPeriod> onPeriodChanged;

  const PaymentChartsSection({
    super.key,
    required this.stats,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  List<AdminPaymentTrendPoint> get _activeTrends {
    switch (selectedPeriod) {
      case AdminPaymentPeriod.weekly:
        return stats.weeklyTrends;
      case AdminPaymentPeriod.monthly:
        return stats.monthlyTrends;
      case AdminPaymentPeriod.daily:
        return stats.dailyTrends;
    }
  }

  String get _periodSubtitle {
    switch (selectedPeriod) {
      case AdminPaymentPeriod.daily:
        return 'Total nominal & volume transaksi 7 hari terakhir (t_shipment_payments)';
      case AdminPaymentPeriod.weekly:
        return 'Total nominal & volume transaksi 4 minggu terakhir (t_shipment_payments)';
      case AdminPaymentPeriod.monthly:
        return 'Total nominal & volume transaksi 6 bulan terakhir (t_shipment_payments)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildPeriodTrendCard(context, isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: _buildDistributionCard(context, isDark),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPeriodTrendCard(context, isDark),
              const SizedBox(height: 16),
              _buildDistributionCard(context, isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildPeriodTrendCard(BuildContext context, bool isDark) {
    final points = _activeTrends;
    num maxVal = 0;
    num periodTotalAmount = 0;
    int periodTotalCount = 0;

    for (final p in points) {
      if (p.totalAmount > maxVal) maxVal = p.totalAmount;
      periodTotalAmount += p.totalAmount;
      periodTotalCount += p.transactionCount;
    }

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grafik Nominal Pembayaran per Periode',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _periodSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              _buildPeriodSelector(isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Ringkasan Periode Aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Akumulasi Periode Ini:',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${AdminCurrencyFormatter.formatRupiah(periodTotalAmount)} ($periodTotalCount transaksi)',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart Visualisasi
          if (points.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('Belum ada data transaksi pada periode ini.'),
              ),
            )
          else
            SizedBox(
              height: 195,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((pt) {
                  final totalRatio =
                      maxVal > 0 ? (pt.totalAmount / maxVal).toDouble() : 0.0;
                  final paidRatio =
                      maxVal > 0 ? (pt.paidAmount / maxVal).toDouble() : 0.0;
                  final barHeight = max(6.0, totalRatio * 130.0);
                  final paidHeight =
                      pt.paidAmount > 0 ? max(4.0, paidRatio * 130.0) : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message:
                            '${pt.label}\nTotal: ${AdminCurrencyFormatter.formatRupiah(pt.totalAmount)} (${pt.transactionCount} trx)\nLunas: ${AdminCurrencyFormatter.formatRupiah(pt.paidAmount)} (${pt.paidCount} trx)\nCOD: ${AdminCurrencyFormatter.formatRupiah(pt.codAmount)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              pt.totalAmount > 0
                                  ? AdminCurrencyFormatter.formatCompactRupiah(
                                      pt.totalAmount,
                                    )
                                  : 'Rp0',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: pt.totalAmount > 0
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 28,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                if (paidHeight > 0)
                                  Container(
                                    width: 28,
                                    height: min(barHeight, paidHeight),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pt.label,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${pt.transactionCount} trx',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 9,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(
                color: AppColors.primary.withValues(alpha: 0.35),
                label: 'Total Nilai Transaksi',
              ),
              const SizedBox(width: 16),
              _buildLegendDot(
                color: AppColors.success,
                label: 'Terverifikasi Lunas (PAID)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final options = [
      (AdminPaymentPeriod.daily, 'Harian'),
      (AdminPaymentPeriod.weekly, 'Mingguan'),
      (AdminPaymentPeriod.monthly, 'Bulanan'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = selectedPeriod == opt.$1;
          return InkWell(
            onTap: () => onPeriodChanged(opt.$1),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt.$2,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionCard(BuildContext context, bool isDark) {
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
          Text(
            'Distribusi Metode & Status Pembayaran',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Proporsi aktual berdasarkan metode dan status pada t_shipment_payments',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Bagian 1: Metode Pembayaran
          Text(
            'Berdasarkan Metode Pembayaran',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (stats.methodDistribution.isEmpty)
            Text(
              'Belum ada data metode pembayaran.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...stats.methodDistribution.map(
              (item) => _buildProgressRow(
                label: item.label,
                count: item.count,
                amount: item.totalAmount,
                percentage: item.percentage,
                color: item.code == 'COD'
                    ? AppColors.secondary
                    : AppColors.primary,
                isDark: isDark,
              ),
            ),

          const Divider(height: 24),

          // Bagian 2: Status Pembayaran
          Text(
            'Berdasarkan Status Pembayaran',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (stats.statusDistribution.isEmpty)
            Text(
              'Belum ada data status pembayaran.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...stats.statusDistribution.map(
              (item) => _buildProgressRow(
                label: item.label,
                count: item.count,
                amount: item.totalAmount,
                percentage: item.percentage,
                color: AdminStatusHelper.getPaymentStatusColor(
                  item.code,
                  isDark: isDark,
                ),
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int count,
    required num amount,
    required double percentage,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$label ($count trx)',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${AdminCurrencyFormatter.formatRupiah(amount)} • ${percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

