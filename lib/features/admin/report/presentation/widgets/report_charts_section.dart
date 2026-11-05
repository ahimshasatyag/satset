import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';

class ReportChartsSection extends StatelessWidget {
  final AdminReportDataResult reportData;

  const ReportChartsSection({
    super.key,
    required this.reportData,
  });

  String _primaryChartTitle() {
    switch (reportData.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return 'Distribusi Beban Tugas per Kurir';
      case AdminReportType.customer:
        return 'Komposisi Verifikasi & Nilai Transaksi Pelanggan';
      case AdminReportType.payment:
        return 'Distribusi Status Pembayaran (t_shipment_payments)';
      case AdminReportType.shipment:
      default:
        return 'Distribusi Paket Berdasarkan Status (m_shipment_statuses)';
    }
  }

  String _secondaryChartTitle() {
    switch (reportData.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return 'Komposisi Penyelesaian Tugas Kurir';
      case AdminReportType.customer:
        return 'Preferensi Metode Pembayaran Pelanggan';
      case AdminReportType.payment:
        return 'Perbandingan Metode Pembayaran (Gateway vs COD)';
      case AdminReportType.shipment:
      default:
        return 'Kontribusi Paket per Jenis Layanan (m_service_types)';
    }
  }

  String _trendChartTitle() {
    switch (reportData.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return 'Grafik Perbandingan Performa Kurir (Tugas vs Selesai vs Berjalan)';
      case AdminReportType.customer:
        return 'Grafik Pelanggan Teraktif Berdasarkan Volume Pengiriman';
      case AdminReportType.payment:
        return 'Grafik Tren Transaksi Pembayaran Harian';
      case AdminReportType.shipment:
      default:
        return 'Grafik Tren Operasional Pengiriman Harian';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 920;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _DistributionCard(
                      title: _primaryChartTitle(),
                      points: reportData.distributionChart,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _DistributionCard(
                      title: _secondaryChartTitle(),
                      points: reportData.secondaryDistributionChart,
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DistributionCard(
                  title: _primaryChartTitle(),
                  points: reportData.distributionChart,
                ),
                const SizedBox(height: 16),
                _DistributionCard(
                  title: _secondaryChartTitle(),
                  points: reportData.secondaryDistributionChart,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _trendChartTitle(),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 14,
                    children: [
                      _LegendIndicator(
                        label: reportData.reportType == AdminReportType.payment
                            ? 'Total Transaksi'
                            : 'Total Paket / Tugas',
                        opacity: 1.0,
                      ),
                      _LegendIndicator(
                        label: reportData.reportType == AdminReportType.payment
                            ? 'Lunas (PAID)'
                            : 'Selesai (DELIVERED)',
                        opacity: 0.55,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (reportData.trendChart.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Belum ada data grafik untuk filter yang dipilih.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 210,
                  child: _ComparativeBarChart(points: reportData.trendChart),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final String title;
  final List<AdminReportChartPoint> points;

  const _DistributionCard({
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada data distribusi pada filter saat ini.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ...points.map((pt) {
              final ratio = (pt.percentage / 100.0).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pt.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pt.count} (${pt.percentage.toStringAsFixed(1)}%)',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (pt.amount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${AdminCurrencyFormatter.formatRupiah(pt.amount)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.surfaceVariantLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ComparativeBarChart extends StatelessWidget {
  final List<AdminReportTrendPoint> points;

  const _ComparativeBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final maxVal = points.fold<int>(
      1,
      (prev, el) => math.max(prev, math.max(el.primaryCount, el.secondaryCount)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((pt) {
                final h1 = (pt.primaryCount / maxVal) * 125.0;
                final h2 = (pt.secondaryCount / maxVal) * 125.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${pt.primaryCount} / ${pt.secondaryCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (pt.totalAmount > 0)
                        Text(
                          AdminCurrencyFormatter.formatRupiah(pt.totalAmount),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 9.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: math.max(h1, 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 18,
                            height: math.max(h2, 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.45),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 84,
                        child: Text(
                          pt.label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final String label;
  final double opacity;

  const _LegendIndicator({
    required this.label,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

