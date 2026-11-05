import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';

class ReportTypeTabs extends StatelessWidget {
  final String selectedReportType;
  final ValueChanged<String> onReportTypeSelected;
  final ValueChanged<AdminReportExportFormat> onExportRequested;
  final int totalFilteredRecords;

  const ReportTypeTabs({
    super.key,
    required this.selectedReportType,
    required this.onReportTypeSelected,
    required this.onExportRequested,
    required this.totalFilteredRecords,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = [
      (
        type: AdminReportType.shipment,
        label: 'Laporan Pengiriman',
        subtitle: 't_shipments & m_shipment_statuses',
        icon: Icons.local_shipping_outlined,
      ),
      (
        type: AdminReportType.courier,
        label: 'Performa Kurir',
        subtitle: 'm_employee & t_shipment_assignments',
        icon: Icons.two_wheeler_outlined,
      ),
      (
        type: AdminReportType.customer,
        label: 'Aktivitas Pelanggan',
        subtitle: 'm_users & riwayat transaksi',
        icon: Icons.people_outline_rounded,
      ),
      (
        type: AdminReportType.payment,
        label: 'Transaksi Pembayaran',
        subtitle: 't_shipment_payments (Gateway & COD)',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jenis Laporan & Ekspor Dokumen',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih kategori laporan operasional untuk memperbarui metrik, grafik, dan tabel secara dinamis.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: totalFilteredRecords > 0
                        ? () => onExportRequested(AdminReportExportFormat.csv)
                        : null,
                    icon: const Icon(Icons.table_rows_outlined, size: 17),
                    label: const Text('Ekspor CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: totalFilteredRecords > 0
                        ? () => onExportRequested(AdminReportExportFormat.excel)
                        : null,
                    icon: const Icon(Icons.grid_on_rounded, size: 17),
                    label: const Text('Ekspor Excel'),
                  ),
                  FilledButton.icon(
                    onPressed: totalFilteredRecords > 0
                        ? () => onExportRequested(AdminReportExportFormat.pdf)
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('Ekspor PDF / Cetak'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1050
                  ? 4
                  : (constraints.maxWidth > 620 ? 2 : 1);
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (crossCount - 1))) /
                  crossCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tabs.map((tab) {
                  final isSelected =
                      selectedReportType.toUpperCase() == tab.type;
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onReportTypeSelected(tab.type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                                  .withValues(alpha: isDark ? 0.2 : 0.08)
                              : (isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 22,
                              color: isSelected
                                  ? colorScheme.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tab.label,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : (isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tab.subtitle,
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
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

