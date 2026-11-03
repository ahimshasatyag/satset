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
    super.dispose();
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
    final data = widget.reportData;
    final filter = data.appliedFilter;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menampilkan ${data.totalFilteredCount} baris data aktual dari database Supabase',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                SizedBox(
                  width: 360,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: _searchHint(),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded, size: 16),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Isi Tabel atau Empty State
          if (data.totalFilteredCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak Ada Data Laporan Ditemukan',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak terdapat rekaman pada database yang cocok dengan kombinasi filter saat ini.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 340,
                ),
                child: _buildTableByReportType(context, data, filter),
              ),
            ),

          const Divider(height: 1),

          // Baris Ringkasan Total Sesuai Filter + Paginasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  _totalFooterLabel(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halaman ${data.currentPage} dari ${data.totalPages}',
                      style: AppTextStyles.bodySmall,
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
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentTable(
    BuildContext context,
    List<AdminShipmentReportRow> rows,
    AdminReportFilter filter,
  ) {
    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      columns: [
        _sortableColumn('No. Resi', 'nomor_resi', filter),
        _sortableColumn('Tanggal', 'created_at', filter),
        _sortableColumn('Pelanggan & Rute', 'customer', filter),
        _sortableColumn('Layanan', 'layanan', filter),
        _sortableColumn('Status Pengiriman', 'status', filter),
        DataColumn(
          label: Text(
            'Kurir Bertugas',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _sortableColumn('Berat (gr)', 'berat', filter, numeric: true),
        _sortableColumn('Total Biaya', 'total_biaya', filter, numeric: true),
        DataColumn(
          label: Text(
            'Pembayaran',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Aksi',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.nomorResi,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text(
                AdminDateFormatter.formatDateTime(r.createdAt),
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.customerNama,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${r.pengirimKota} -> ${r.penerimaKota}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
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
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(
              Text(
                r.totalBeratGram.toStringAsFixed(0),
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.totalBiaya),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text(
                '${r.metodePembayaran} • ${r.statusPembayaran}',
                style: AppTextStyles.bodySmall,
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
    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      columns: [
        _sortableColumn('Kurir & Kode Employee', 'nama', filter),
        DataColumn(
          label: Text(
            'Kontak & Status',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
        DataColumn(
          label: Text(
            'Bukti & GPS',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Aksi',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    r.employeeCode,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.noHp, style: AppTextStyles.bodySmall),
                  Text(
                    r.isActive ? 'Akun Aktif' : 'Akun Nonaktif',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                '${r.totalAssigned}',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(Text('${r.deliveredCount}', style: AppTextStyles.bodySmall)),
            DataCell(
              Text('${r.inProgressCount}', style: AppTextStyles.bodySmall),
            ),
            DataCell(
              Text(
                '${r.failedOrReturnedCount}',
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(
              _StatusTag(text: '${r.completionRate.toStringAsFixed(1)}%'),
            ),
            DataCell(
              Text(
                '${r.proofUploadedCount} Bukti • ${r.gpsLocationsCount} GPS',
                style: AppTextStyles.bodySmall,
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
    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      columns: [
        _sortableColumn('Nama Pelanggan', 'nama', filter),
        DataColumn(
          label: Text(
            'Kontak & Verifikasi',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _sortableColumn(
          'Total Pengiriman',
          'total_shipments',
          filter,
          numeric: true,
        ),
        _sortableColumn('Selesai', 'delivered', filter, numeric: true),
        DataColumn(
          label: Text(
            'Berjalan / Batal',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Metode Dominan',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _sortableColumn(
          'Total Nilai Transaksi',
          'total_spend',
          filter,
          numeric: true,
        ),
        _sortableColumn('Transaksi Terakhir', 'last_shipment', filter),
        DataColumn(
          label: Text(
            'Aksi',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.namaLengkap,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.email, style: AppTextStyles.bodySmall),
                  Text(
                    '${r.noHp} • ${r.emailVerified ? 'Terverifikasi' : 'Belum Verifikasi'}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                '${r.totalShipments}',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text('${r.deliveredShipments}', style: AppTextStyles.bodySmall),
            ),
            DataCell(
              Text(
                '${r.activeShipments} aktif / ${r.failedOrCancelledShipments} gagal',
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(_StatusTag(text: r.preferredPaymentMethod)),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.totalShippingSpend),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text(
                r.lastShipmentAt != null
                    ? AdminDateFormatter.formatShortDate(r.lastShipmentAt)
                    : '-',
                style: AppTextStyles.bodySmall,
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
    return DataTable(
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      columns: [
        _sortableColumn('No. Pembayaran', 'nomor_pembayaran', filter),
        _sortableColumn('No. Resi', 'nomor_resi', filter),
        _sortableColumn('Tanggal Transaksi', 'created_at', filter),
        DataColumn(
          label: Text(
            'Pelanggan & Layanan',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _sortableColumn('Metode', 'metode', filter),
        _sortableColumn('Status Pembayaran', 'status', filter),
        _sortableColumn(
          'Nominal Dibayar',
          'jumlah_bayar',
          filter,
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Waktu Lunas',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Aksi',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      rows: rows.map((r) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                r.nomorPembayaran,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(Text(r.nomorResi, style: AppTextStyles.bodySmall)),
            DataCell(
              Text(
                AdminDateFormatter.formatDateTime(r.createdAt),
                style: AppTextStyles.bodySmall,
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.customerNama,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${r.serviceKode} • ${r.shipmentStatusNama}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            DataCell(_StatusTag(text: r.metodePembayaran)),
            DataCell(_StatusTag(text: r.statusPembayaran)),
            DataCell(
              Text(
                AdminCurrencyFormatter.formatRupiah(r.jumlahBayar),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text(
                r.paidAt != null
                    ? AdminDateFormatter.formatDateTime(r.paidAt)
                    : '-',
                style: AppTextStyles.bodySmall,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

