import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_item.dart';
import 'payment_filter_bar.dart';
import 'payment_skeleton.dart';

class PaymentDataTable extends StatefulWidget {
  final AdminPaymentsPaginatedResult paymentsResult;
  final bool isLoading;
  final bool isActionInProgress;
  final String searchQuery;
  final String methodFilter;
  final String statusFilter;
  final String jenisBankFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final num? minAmount;
  final num? maxAmount;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    num? minAmount,
    num? maxAmount,
    bool clearDates,
    bool clearAmounts,
  }) onFiltersChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onExportPressed;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onViewDetail;
  final ValueChanged<AdminPaymentItem> onReconcilePayment;
  final ValueChanged<AdminPaymentItem> onConfirmCodPayment;

  const PaymentDataTable({
    super.key,
    required this.paymentsResult,
    required this.isLoading,
    this.isActionInProgress = false,
    required this.searchQuery,
    required this.methodFilter,
    required this.statusFilter,
    required this.jenisBankFilter,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onResetFilters,
    required this.onExportPressed,
    required this.onPageChanged,
    required this.onViewDetail,
    required this.onReconcilePayment,
    required this.onConfirmCodPayment,
  });

  @override
  State<PaymentDataTable> createState() => _PaymentDataTableState();
}

class _PaymentDataTableState extends State<PaymentDataTable> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Widget _buildSortableHeader(String label, String columnKey) {
    final isSorted = widget.sortColumn == columnKey;
    return InkWell(
      onTap: () => widget.onSortChanged(columnKey),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(
              isSorted
                  ? (widget.sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: isSorted ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.paymentsResult.items;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Tabel + Tombol Ekspor Laporan + Filter Bar Terpadu
          Padding(
            padding: const EdgeInsets.all(20),
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
                          'Daftar Transaksi Pembayaran (t_shipment_payments)',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Menampilkan ${items.length} dari ${widget.paymentsResult.totalCount} transaksi terfilter (Relasi t_shipments, m_users, m_jenis_bank & m_bank)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading || widget.isActionInProgress)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: widget.onExportPressed,
                          icon: const Icon(
                            Icons.download_rounded,
                            size: 16,
                          ),
                          label: const Text('Ekspor Laporan CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PaymentFilterBar(
                  searchQuery: widget.searchQuery,
                  methodFilter: widget.methodFilter,
                  statusFilter: widget.statusFilter,
                  jenisBankFilter: widget.jenisBankFilter,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  minAmount: widget.minAmount,
                  maxAmount: widget.maxAmount,
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
                  bankReferences: widget.paymentsResult.bankReferences,
                  onSearchChanged: widget.onSearchChanged,
                  onFiltersChanged: widget.onFiltersChanged,
                  onSortChanged: widget.onSortChanged,
                  onResetFilters: widget.onResetFilters,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // 2. Konten Tabel
          if (widget.isLoading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: PaymentTableRowsSkeleton(rowCount: 6),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 52,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak Ada Transaksi Pembayaran Ditemukan',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum ada transaksi pada t_shipment_payments yang sesuai dengan kata kunci atau filter aktif saat ini.',
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
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 74,
                    dataRowMaxHeight: 92,
                    columnSpacing: 22,
                    horizontalMargin: 20,
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? AppColors.backgroundDark.withValues(alpha: 0.6)
                          : AppColors.backgroundLight,
                    ),
                    columns: [
                      DataColumn(
                        label: _buildSortableHeader(
                          'ID & Referensi Pembayaran',
                          'nomor_pembayaran',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Nomor Resi & Layanan',
                          'nomor_resi',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Customer & Rute',
                          'customer_nama',
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'Metode & Bank / Gateway',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Nominal & Tagihan',
                          'jumlah_bayar',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Status Pembayaran',
                          'status_pembayaran',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Waktu Transaksi & Batas',
                          'created_at',
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'Aksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: items
                        .map((item) => _buildDataRow(item, isDark))
                        .toList(),
                  ),
                ),
              ),
            ),

          // 3. Footer Paginasi
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  'Halaman ${widget.paymentsResult.currentPage} dari ${widget.paymentsResult.totalPages} (Total ${widget.paymentsResult.totalCount} transaksi)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.paymentsResult.currentPage > 1
                          ? () => widget.onPageChanged(
                                widget.paymentsResult.currentPage - 1,
                              )
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: const Text('Sebelumnya'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.paymentsResult.currentPage <
                              widget.paymentsResult.totalPages
                          ? () => widget.onPageChanged(
                                widget.paymentsResult.currentPage + 1,
                              )
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      label: const Text('Berikutnya'),
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

  DataRow _buildDataRow(AdminPaymentItem item, bool isDark) {
    final normStatus = item.normalizedStatus;
    final displayStatusCode =
        item.isCod && !item.isPaid ? 'COD' : normStatus;
    final statusColor = AdminStatusHelper.getPaymentStatusColor(
      displayStatusCode,
      isDark: isDark,
    );
    final statusLabel = item.isCod
        ? (item.isPaid ? 'COD Lunas (PAID)' : 'COD Belum Disetor')
        : AdminStatusHelper.getPaymentStatusLabel(normStatus);

    final shipmentStatusColor = AdminStatusHelper.getStatusColor(
      item.shipmentStatusKode,
      isDark: isDark,
    );

    return DataRow(
      cells: [
        // 1. ID & Referensi Pembayaran
        DataCell(
          InkWell(
            onTap: () => widget.onViewDetail(item.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.nomorPembayaran,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID #${item.id} • Ref: ${item.providerReference ?? "-"}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
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
        ),

        // 2. Nomor Resi & Jenis Layanan
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.nomorResi,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.serviceNama,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: shipmentStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.shipmentStatusNama,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        color: shipmentStatusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Customer & Rute
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.customerNama,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.customerNoHp != '-'
                      ? item.customerNoHp
                      : item.customerEmail,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.pengirimKota} → ${item.penerimaKota}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // 4. Metode & Bank / Gateway
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isCod
                        ? Icons.handshake_rounded
                        : Icons.account_balance_rounded,
                    size: 14,
                    color: item.isCod ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.metodePembayaran,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          item.isCod ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.isCod
                    ? 'Tagih Penerima: ${item.penerimaNama}'
                    : (item.namaJenisBank != null &&
                            item.namaJenisBank!.isNotEmpty
                        ? 'Bank ${item.namaJenisBank} (${item.nomorRekeningBank ?? item.providerReference ?? "-"})'
                        : 'Channel: ${item.provider ?? "Gateway"}'),
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // 5. Nominal & Tagihan
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AdminCurrencyFormatter.formatRupiah(item.jumlahBayar),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isAmountMatched
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 12,
                    color: item.isAmountMatched
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.isAmountMatched
                        ? 'Sesuai Tagihan'
                        : 'Tagihan: ${AdminCurrencyFormatter.formatRupiah(item.totalBiayaShipment)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: item.isAmountMatched
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 6. Status Pembayaran
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isPaid
                      ? Icons.verified_rounded
                      : (item.isCod
                          ? Icons.payments_outlined
                          : (item.isExpired
                              ? Icons.timer_off_outlined
                              : Icons.schedule_rounded)),
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. Waktu Transaksi & Batas Pembayaran
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dibuat: ${AdminDateFormatter.formatDateTime(item.createdAt)}',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
              ),
              if (item.paidAt != null)
                Text(
                  'Lunas: ${AdminDateFormatter.formatDateTime(item.paidAt)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (item.expiredAt != null && !item.isCod)
                Text(
                  'Batas: ${AdminDateFormatter.formatDateTime(item.expiredAt)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: item.isExpired ? AppColors.error : AppColors.warning,
                  ),
                )
              else
                Text(
                  item.isCod
                      ? 'Ditagih saat paket diserahkan'
                      : 'Menunggu konfirmasi webhook',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),

        // 8. Aksi
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Lihat Detail Pembayaran, Info Gateway/Bank & Audit',
                child: IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () => widget.onViewDetail(item.id),
                ),
              ),
              Tooltip(
                message:
                    'Rekonsiliasi & Validasi Status Pembayaran via Backend',
                child: IconButton(
                  icon: const Icon(
                    Icons.sync_lock_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                  onPressed: widget.isActionInProgress
                      ? null
                      : () => widget.onReconcilePayment(item),
                ),
              ),
              if (item.isCod && !item.isPaid)
                Tooltip(
                  message: 'Verifikasi & Konfirmasi Setoran COD Lunas',
                  child: IconButton(
                    icon: const Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    onPressed: widget.isActionInProgress
                        ? null
                        : () => widget.onConfirmCodPayment(item),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

