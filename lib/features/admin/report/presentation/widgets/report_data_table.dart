import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';

class ReportDataTable extends StatefulWidget {
  final AdminReportDataResult reportData;
  final ValueChanged<String> onSearchChanged;
  final void Function(String column, bool ascending) onSortChanged;
  final ValueChanged<int> onPageChanged;
  final void Function(String reportType, int recordId) onViewDetail;

  const ReportDataTable({
    super.key,
    required this.reportData,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onViewDetail,
  });

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  late final TextEditingController _searchController;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.reportData.appliedFilter.searchQuery,
    );
  }

  @override
  void didUpdateWidget(covariant ReportDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSearch = widget.reportData.appliedFilter.searchQuery;
    if (newSearch != _searchController.text) {
      _searchController.text = newSearch;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _scrollTableLeft() {
    if (_horizontalScrollController.hasClients) {
      final target = (_horizontalScrollController.offset - 280).clamp(
        0.0,
        _horizontalScrollController.position.maxScrollExtent,
      );
      _horizontalScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollTableRight() {
    if (_horizontalScrollController.hasClients) {
      final target = (_horizontalScrollController.offset + 280).clamp(
        0.0,
        _horizontalScrollController.position.maxScrollExtent,
      );
      _horizontalScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _searchHint() {
    switch (widget.reportData.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return 'Cari nama kurir, kode employee, email, atau no. HP...';
      case AdminReportType.customer:
        return 'Cari nama pelanggan, email, atau nomor telepon...';
      case AdminReportType.payment:
        return 'Cari nomor pembayaran, nomor resi, pelanggan, atau referensi gateway...';
      case AdminReportType.shipment:
      default:
        return 'Cari nomor resi, pelanggan, pengirim, penerima, kota, atau kurir...';
    }
  }

  String _totalFooterLabel() {
    final data = widget.reportData;
    switch (data.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return 'Total Sesuai Filter: ${data.totalFilteredCount} Kurir • ${data.filteredSecondaryTotal.toInt()} Tugas Penugasan • Akumulasi COD: ${AdminCurrencyFormatter.formatRupiah(data.filteredTotalAmount)}';
      case AdminReportType.customer:
        return 'Total Sesuai Filter: ${data.totalFilteredCount} Pelanggan • ${data.filteredSecondaryTotal.toInt()} Pengiriman • Total Nilai Transaksi: ${AdminCurrencyFormatter.formatRupiah(data.filteredTotalAmount)}';
      case AdminReportType.payment:
        return 'Total Sesuai Filter: ${data.totalFilteredCount} Transaksi • Tagihan: ${AdminCurrencyFormatter.formatRupiah(data.filteredSecondaryTotal)} • Total Nominal Pembayaran: ${AdminCurrencyFormatter.formatRupiah(data.filteredTotalAmount)}';
      case AdminReportType.shipment:
      default:
        final kg = (data.filteredSecondaryTotal / 1000.0).toStringAsFixed(1);
        return 'Total Sesuai Filter: ${data.totalFilteredCount} Paket • Berat: $kg Kg • Total Biaya Pengiriman: ${AdminCurrencyFormatter.formatRupiah(data.filteredTotalAmount)}';
    }
  }

  void _triggerSort(String column) {
    final filter = widget.reportData.appliedFilter;
    if (filter.sortColumn == column) {
      widget.onSortChanged(column, !filter.sortAscending);
    } else {
      widget.onSortChanged(column, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.reportData;
    final filter = data.appliedFilter;

    return Container(
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
          // Header Tabel + Pencarian Cepat
          Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabel Rincian ${AdminReportType.labelOf(data.reportType)}',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menampilkan ${data.totalFilteredCount} baris data aktual dari database Supabase',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 360,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: _searchHint(),
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Isi Tabel atau Empty State
          if (data.totalFilteredCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak Ada Data Laporan Ditemukan',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak terdapat rekaman pada database yang cocok dengan kombinasi filter saat ini.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (isDark) {
                            return Colors.white;
                          }
                          return AppColors.primary.withValues(alpha: 0.6);
                        }),
                        trackColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.surfaceVariantLight,
                        ),
                        trackBorderColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      thickness: 9,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: _buildTableByReportType(context, data, filter),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Baris Ringkasan Total Sesuai Filter + Navigasi Scroll & Paginasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _totalFooterLabel(),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Navigasi Scroll Horizontal
                    IconButton(
                      tooltip: 'Geser Tabel ke Kiri',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: _scrollTableLeft,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    IconButton(
                      tooltip: 'Geser Tabel ke Kanan',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: _scrollTableRight,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halaman ${data.currentPage} dari ${data.totalPages}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Halaman Sebelumnya',
                      onPressed: data.currentPage > 1
                          ? () => widget.onPageChanged(data.currentPage - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      tooltip: 'Halaman Berikutnya',
                      onPressed: data.currentPage < data.totalPages
                          ? () => widget.onPageChanged(data.currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableByReportType(
    BuildContext context,
    AdminReportDataResult data,
    AdminReportFilter filter,
  ) {
    switch (data.reportType.toUpperCase()) {
      case AdminReportType.courier:
        return _buildCourierTable(context, data.courierRows, filter);
      case AdminReportType.customer:
        return _buildCustomerTable(context, data.customerRows, filter);
      case AdminReportType.payment:
        return _buildPaymentTable(context, data.paymentRows, filter);
      case AdminReportType.shipment:
      default:
        return _buildShipmentTable(context, data.shipmentRows, filter);
    }
  }

  DataColumn _sortableColumn(
    String label,
    String columnKey,
    AdminReportFilter filter, {
    bool numeric = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSorted = filter.sortColumn == columnKey;
    return DataColumn(
      numeric: numeric,
      onSort: (_, _) => _triggerSort(columnKey),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isSorted
                ? (filter.sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
            size: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  DataColumn _staticColumn(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DataColumn(
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildShipmentTable(
    BuildContext context,
    List<AdminShipmentReportRow> rows,
    AdminReportFilter filter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryStyle = AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final boldPrimaryStyle = AppTextStyles.labelMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final mediumPrimaryStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final secondarySubStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 11,
      color:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
      ),
      columns: [
        _sortableColumn('No. Resi', 'nomor_resi', filter),
        _sortableColumn('Tanggal', 'created_at', filter),
        _sortableColumn('Pelanggan & Rute', 'customer', filter),
        _sortableColumn('Layanan', 'layanan', filter),
        _sortableColumn('Status Pengiriman', 'status', filter),
        _staticColumn('Kurir Bertugas'),
        _sortableColumn('Berat (gr)', 'berat', filter, numeric: true),
        _sortableColumn('Total Biaya', 'total_biaya', filter, numeric: true),
        _staticColumn('Pembayaran'),
        _staticColumn('Aksi'),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.nomorResi,
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Text(
                AdminDateFormatter.formatDateTime(r.createdAt),
                style: primaryStyle,
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.customerNama,
                    style: mediumPrimaryStyle,
                  ),
                  Text(
                    '${r.pengirimKota} -> ${r.penerimaKota}',
                    style: secondarySubStyle,
                  ),
                ],
              ),
            ),
            DataCell(
              _StatusTag(text: '${r.serviceKode} (${r.serviceNama})'),
            ),
            DataCell(
              _StatusTag(text: '${r.statusNama} [${r.statusKode}]'),
            ),
            DataCell(
              Text(
                r.courierNama != null
                    ? '${r.courierNama} (${r.courierCode ?? '-'})'
                    : 'Belum Ditugaskan',
                style: primaryStyle,
              ),
            ),
            DataCell(
              Text(
                r.totalBeratGram.toStringAsFixed(0),
                style: primaryStyle,
              ),
            ),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.totalBiaya),
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Text(
                '${r.metodePembayaran} • ${r.statusPembayaran}',
                style: primaryStyle,
              ),
            ),
            DataCell(
              OutlinedButton.icon(
                onPressed: () => widget.onViewDetail(
                  AdminReportType.shipment,
                  r.shipmentId,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detail'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCourierTable(
    BuildContext context,
    List<AdminCourierReportRow> rows,
    AdminReportFilter filter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryStyle = AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final boldPrimaryStyle = AppTextStyles.labelMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final secondarySubStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 11,
      color:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
      ),
      columns: [
        _sortableColumn('Kurir & Kode Employee', 'nama', filter),
        _staticColumn('Kontak & Status'),
        _sortableColumn(
          'Tugas Diterima',
          'total_assigned',
          filter,
          numeric: true,
        ),
        _sortableColumn(
          'Berhasil (DELIVERED)',
          'delivered',
          filter,
          numeric: true,
        ),
        _sortableColumn('Berjalan', 'in_progress', filter, numeric: true),
        _sortableColumn('Gagal / Retur', 'failed', filter, numeric: true),
        _sortableColumn(
          'Rasio Selesai',
          'completion_rate',
          filter,
          numeric: true,
        ),
        _staticColumn('Bukti & GPS'),
        _staticColumn('Aksi'),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.namaLengkap,
                    style: boldPrimaryStyle,
                  ),
                  Text(
                    r.employeeCode,
                    style: secondarySubStyle,
                  ),
                ],
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.noHp, style: primaryStyle),
                  Text(
                    r.isActive ? 'Akun Aktif' : 'Akun Nonaktif',
                    style: secondarySubStyle,
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                '${r.totalAssigned}',
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(Text('${r.deliveredCount}', style: primaryStyle)),
            DataCell(
              Text('${r.inProgressCount}', style: primaryStyle),
            ),
            DataCell(
              Text(
                '${r.failedOrReturnedCount}',
                style: primaryStyle,
              ),
            ),
            DataCell(
              _StatusTag(text: '${r.completionRate.toStringAsFixed(1)}%'),
            ),
            DataCell(
              Text(
                '${r.proofUploadedCount} Bukti • ${r.gpsLocationsCount} GPS',
                style: primaryStyle,
              ),
            ),
            DataCell(
              OutlinedButton.icon(
                onPressed: () =>
                    widget.onViewDetail(AdminReportType.courier, r.courierId),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detail'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomerTable(
    BuildContext context,
    List<AdminCustomerReportRow> rows,
    AdminReportFilter filter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryStyle = AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final boldPrimaryStyle = AppTextStyles.labelMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final secondarySubStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 11,
      color:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
      ),
      columns: [
        _sortableColumn('Nama Pelanggan', 'nama', filter),
        _staticColumn('Kontak & Verifikasi'),
        _sortableColumn(
          'Total Pengiriman',
          'total_shipments',
          filter,
          numeric: true,
        ),
        _sortableColumn('Selesai', 'delivered', filter, numeric: true),
        _staticColumn('Berjalan / Batal'),
        _staticColumn('Metode Dominan'),
        _sortableColumn(
          'Total Nilai Transaksi',
          'total_spend',
          filter,
          numeric: true,
        ),
        _sortableColumn('Transaksi Terakhir', 'last_shipment', filter),
        _staticColumn('Aksi'),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.namaLengkap,
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.email, style: primaryStyle),
                  Text(
                    '${r.noHp} • ${r.emailVerified ? 'Terverifikasi' : 'Belum Verifikasi'}',
                    style: secondarySubStyle,
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                '${r.totalShipments}',
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Text('${r.deliveredShipments}', style: primaryStyle),
            ),
            DataCell(
              Text(
                '${r.activeShipments} aktif / ${r.failedOrCancelledShipments} gagal',
                style: primaryStyle,
              ),
            ),
            DataCell(_StatusTag(text: r.preferredPaymentMethod)),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.totalShippingSpend),
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Text(
                r.lastShipmentAt != null
                    ? AdminDateFormatter.formatShortDate(r.lastShipmentAt)
                    : '-',
                style: primaryStyle,
              ),
            ),
            DataCell(
              OutlinedButton.icon(
                onPressed: () => widget.onViewDetail(
                  AdminReportType.customer,
                  r.customerId,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detail'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPaymentTable(
    BuildContext context,
    List<AdminPaymentReportRow> rows,
    AdminReportFilter filter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryStyle = AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final boldPrimaryStyle = AppTextStyles.labelMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final mediumPrimaryStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final secondarySubStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 11,
      color:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
      ),
      columns: [
        _sortableColumn('No. Pembayaran', 'nomor_pembayaran', filter),
        _sortableColumn('No. Resi', 'nomor_resi', filter),
        _sortableColumn('Tanggal Transaksi', 'created_at', filter),
        _staticColumn('Pelanggan & Layanan'),
        _sortableColumn('Metode', 'metode', filter),
        _sortableColumn('Status Pembayaran', 'status', filter),
        _sortableColumn(
          'Nominal Dibayar',
          'jumlah_bayar',
          filter,
          numeric: true,
        ),
        _staticColumn('Waktu Lunas'),
        _staticColumn('Aksi'),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.nomorPembayaran,
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(Text(r.nomorResi, style: primaryStyle)),
            DataCell(
              Text(
                AdminDateFormatter.formatDateTime(r.createdAt),
                style: primaryStyle,
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.customerNama,
                    style: mediumPrimaryStyle,
                  ),
                  Text(
                    '${r.serviceKode} • ${r.shipmentStatusNama}',
                    style: secondarySubStyle,
                  ),
                ],
              ),
            ),
            DataCell(_StatusTag(text: r.metodePembayaran)),
            DataCell(_StatusTag(text: r.statusPembayaran)),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.jumlahBayar),
                style: boldPrimaryStyle,
              ),
            ),
            DataCell(
              Text(
                r.paidAt != null
                    ? AdminDateFormatter.formatDateTime(r.paidAt)
                    : '-',
                style: primaryStyle,
              ),
            ),
            DataCell(
              OutlinedButton.icon(
                onPressed: () =>
                    widget.onViewDetail(AdminReportType.payment, r.paymentId),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detail'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String text;

  const _StatusTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

