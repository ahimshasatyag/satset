import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';

class ReportSummaryCards extends StatelessWidget {
  final AdminReportDataResult reportData;

  const ReportSummaryCards({
    super.key,
    required this.reportData,
  });

  List<_SummaryMetricItem> _buildMetrics() {
    switch (reportData.reportType.toUpperCase()) {
      case AdminReportType.courier:
        final s = reportData.courierSummary;
        return [
          _SummaryMetricItem(
            title: 'Total Kurir Terdaftar',
            value: '${s.totalCouriers} Kurir',
            subtitle: '${s.activeCouriers} akun kurir aktif (id_users_role = 2)',
            badge: 'm_employee',
            icon: Icons.badge_outlined,
          ),
          _SummaryMetricItem(
            title: 'Tugas Diterima',
            value: '${s.totalAssignedTasks} Tugas',
            subtitle: 'Riwayat penugasan aktif kurir',
            badge: 't_shipment_assignments',
            icon: Icons.assignment_ind_outlined,
          ),
          _SummaryMetricItem(
            title: 'Pengiriman Berhasil',
            value: '${s.deliveredTasks} Paket',
            subtitle:
                'Rasio keberhasilan: ${s.averageSuccessRate.toStringAsFixed(1)}%',
            badge: 'DELIVERED',
            icon: Icons.task_alt_rounded,
          ),
          _SummaryMetricItem(
            title: 'Tugas Masih Berjalan',
            value: '${s.inProgressTasks} Paket',
            subtitle: 'Dalam penjemputan / pengantaran aktif',
            badge: 'ONGOING',
            icon: Icons.directions_bike_rounded,
          ),
          _SummaryMetricItem(
            title: 'Gagal / Dikembalikan',
            value: '${s.failedOrReturnedTasks} Paket',
            subtitle: 'Status FAILED_DELIVERY atau RETURNED',
            badge: 'EVALUASI',
            icon: Icons.report_problem_outlined,
          ),
          _SummaryMetricItem(
            title: 'Bukti Kirim & Log GPS',
            value: '${s.totalProofUploaded} Bukti',
            subtitle: '${s.totalGpsLogs} titik koordinat GPS terekam',
            badge: 't_shipment_proofs',
            icon: Icons.fact_check_outlined,
          ),
        ];

      case AdminReportType.customer:
        final s = reportData.customerSummary;
        return [
          _SummaryMetricItem(
            title: 'Total Pelanggan',
            value: '${s.totalCustomers} Akun',
            subtitle: '${s.verifiedCustomers} email pelanggan terverifikasi',
            badge: 'm_users',
            icon: Icons.people_outline_rounded,
          ),
          _SummaryMetricItem(
            title: 'Pelanggan Bertransaksi',
            value: '${s.transactingCustomers} Pelanggan',
            subtitle: 'Memiliki minimal 1 pesanan pengiriman',
            badge: 'AKTIF',
            icon: Icons.person_pin_circle_outlined,
          ),
          _SummaryMetricItem(
            title: 'Total Pengiriman',
            value: '${s.totalShipments} Paket',
            subtitle: '${s.completedShipments} paket telah diterima tujuan',
            badge: 't_shipments',
            icon: Icons.inventory_2_outlined,
          ),
          _SummaryMetricItem(
            title: 'Total Nilai Transaksi',
            value: AdminCurrencyFormatter.formatRupiah(s.totalTransactionValue),
            subtitle: 'Akumulasi biaya pengiriman pelanggan',
            badge: 'GROSS',
            icon: Icons.receipt_long_outlined,
          ),
          _SummaryMetricItem(
            title: 'Transaksi Lunas',
            value: AdminCurrencyFormatter.formatRupiah(s.paidTransactionValue),
            subtitle: 'Nominal pembayaran berstatus PAID',
            badge: 'SETTLED',
            icon: Icons.verified_outlined,
          ),
          _SummaryMetricItem(
            title: 'Rata-rata Pengiriman',
            value: s.transactingCustomers > 0
                ? '${(s.totalShipments / s.transactingCustomers).toStringAsFixed(1)} Paket'
                : '0 Paket',
            subtitle: 'Frekuensi pengiriman per pelanggan aktif',
            badge: 'FREKUENSI',
            icon: Icons.insights_rounded,
          ),
        ];

      case AdminReportType.payment:
        final s = reportData.paymentSummary;
        return [
          _SummaryMetricItem(
            title: 'Total Transaksi',
            value: '${s.totalTransactions} Transaksi',
            subtitle:
                'Total: ${AdminCurrencyFormatter.formatRupiah(s.totalNominal)}',
            badge: 't_shipment_payments',
            icon: Icons.payments_outlined,
          ),
          _SummaryMetricItem(
            title: 'Transfer (Gateway)',
            value: '${s.transferCount} Transaksi',
            subtitle: AdminCurrencyFormatter.formatRupiah(s.transferNominal),
            badge: 'TRANSFER',
            icon: Icons.account_balance_outlined,
          ),
          _SummaryMetricItem(
            title: 'Cash on Delivery (COD)',
            value: '${s.codCount} Transaksi',
            subtitle: AdminCurrencyFormatter.formatRupiah(s.codNominal),
            badge: 'COD',
            icon: Icons.payments_rounded,
          ),
          _SummaryMetricItem(
            title: 'Pembayaran Berhasil',
            value: '${s.paidCount} Transaksi',
            subtitle: AdminCurrencyFormatter.formatRupiah(s.paidNominal),
            badge: 'PAID',
            icon: Icons.check_circle_outline_rounded,
          ),
          _SummaryMetricItem(
            title: 'Menunggu Pembayaran',
            value: '${s.pendingCount} Transaksi',
            subtitle: AdminCurrencyFormatter.formatRupiah(s.pendingNominal),
            badge: 'PENDING',
            icon: Icons.schedule_rounded,
          ),
          _SummaryMetricItem(
            title: 'Gagal / Kedaluwarsa',
            value: '${s.failedCount + s.expiredCount} Transaksi',
            subtitle:
                'Gagal: ${s.failedCount} • Kedaluwarsa: ${s.expiredCount}',
            badge: 'FAILED / EXPIRED',
            icon: Icons.cancel_outlined,
          ),
        ];

      case AdminReportType.shipment:
      default:
        final s = reportData.shipmentSummary;
        final totalKg = (s.totalWeightGrams / 1000.0).toStringAsFixed(1);
        return [
          _SummaryMetricItem(
            title: 'Total Paket Pengiriman',
            value: '${s.totalPackages} Paket',
            subtitle:
                'Total Berat: $totalKg Kg • Nilai: ${AdminCurrencyFormatter.formatRupiah(s.totalRevenue)}',
            badge: 'TOTAL',
            icon: Icons.local_shipping_outlined,
          ),
          _SummaryMetricItem(
            title: 'Paket Berhasil Dikirim',
            value: '${s.deliveredCount} Paket',
            subtitle:
                'Tingkat keberhasilan: ${s.deliverySuccessRate.toStringAsFixed(1)}%',
            badge: 'DELIVERED',
            icon: Icons.check_circle_outline_rounded,
          ),
          _SummaryMetricItem(
            title: 'Paket Dalam Proses',
            value: '${s.inProcessCount} Paket',
            subtitle:
                'Menunggu, dijemput, sortir, transit, atau sedang diantar',
            badge: 'IN PROCESS',
            icon: Icons.sync_rounded,
          ),
          _SummaryMetricItem(
            title: 'Paket Gagal Dikirim',
            value: '${s.failedCount} Paket',
            subtitle: 'Status pengiriman FAILED_DELIVERY',
            badge: 'FAILED_DELIVERY',
            icon: Icons.error_outline_rounded,
          ),
          _SummaryMetricItem(
            title: 'Paket Dibatalkan',
            value: '${s.cancelledCount} Paket',
            subtitle: 'Status pengiriman CANCELLED',
            badge: 'CANCELLED',
            icon: Icons.block_flipped,
          ),
          _SummaryMetricItem(
            title: 'Paket Dikembalikan',
            value: '${s.returnedCount} Paket',
            subtitle: 'Status pengiriman RETURNED (Retur)',
            badge: 'RETURNED',
            icon: Icons.keyboard_return_rounded,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = _buildMetrics();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1150
            ? 3
            : (constraints.maxWidth > 680 ? 2 : 1);
        const spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(m.icon, size: 22),
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
                                  m.title,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Text(
                                  m.badge,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.value,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryMetricItem {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final IconData icon;

  const _SummaryMetricItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });
}
