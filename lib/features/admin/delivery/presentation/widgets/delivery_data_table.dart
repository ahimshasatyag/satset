import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_delivery_item.dart';
import 'delivery_skeleton.dart';

class DeliveryDataTable extends StatefulWidget {
  final AdminDeliveriesPaginatedResult deliveriesResult;
  final bool isLoading;
  final bool isActionInProgress;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onViewDetail;
  final ValueChanged<AdminDeliveryItem> onConfirmOrder;
  final ValueChanged<AdminDeliveryItem> onAssignCourier;
  final ValueChanged<AdminDeliveryItem> onHandleFailed;

  const DeliveryDataTable({
    super.key,
    required this.deliveriesResult,
    required this.isLoading,
    this.isActionInProgress = false,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onViewDetail,
    required this.onConfirmOrder,
    required this.onAssignCourier,
    required this.onHandleFailed,
  });

  @override
  State<DeliveryDataTable> createState() => _DeliveryDataTableState();
}

class _DeliveryDataTableState extends State<DeliveryDataTable> {
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

  String _formatWeight(num grams) {
    if (grams >= 1000) {
      final kg = grams / 1000;
      return '${kg.toStringAsFixed(kg.truncateToDouble() == kg ? 0 : 1)} kg (${grams.toInt()} gr)';
    }
    return '${grams.toInt()} gr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.deliveriesResult.items;

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
          // Header Tabel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Transaksi Pengiriman',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menampilkan ${items.length} dari ${widget.deliveriesResult.totalCount} pengiriman sesuai filter aktif',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                if (widget.isLoading || widget.isActionInProgress)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Kondisi Loading Tabel (Skeleton) atau Kosong
          if (widget.isLoading)
            const DeliveryTableRowsSkeleton(rowCount: 6)
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 52,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak Ada Data Pengiriman',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belum ada transaksi pengiriman yang sesuai dengan pencarian atau filter yang dipilih.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
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
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 8,
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
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                          ),
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 76,
                          horizontalMargin: 20,
                          columnSpacing: 22,
                          columns: [
                            DataColumn(
                              label: _buildSortableHeader(
                                'Resi & Barcode',
                                'nomor_resi',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Customer / Pengirim',
                                'pengirim_nama',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Penerima',
                                'penerima_nama',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Alamat Asal & Tujuan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Layanan & Berat',
                                'total_berat_gram',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Biaya & Pembayaran',
                                'total_biaya',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Kurir Ditugaskan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Status Pengiriman',
                                'status',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Tanggal Pesanan',
                                'created_at',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Aksi Operasional',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: items.map((item) {
                            final statusColor = AdminStatusHelper.getStatusColor(
                              item.statusKode,
                              isDark: isDark,
                            );
                            final statusBg = AdminStatusHelper.getStatusBgColor(
                              item.statusKode,
                              isDark: isDark,
                            );
                            final payStatusColor =
                                AdminStatusHelper.getPaymentStatusColor(
                              item.statusPembayaran,
                              isDark: isDark,
                            );

                            return DataRow(
                              cells: [
                                // 1. Nomor Resi & Barcode
                                DataCell(
                                  InkWell(
                                    onTap: () => widget.onViewDetail(item.id),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.nomorResi,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Barcode: ${item.barcodeValue}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 2. Customer / Pengirim
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.pengirimNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.customerNama != item.pengirimNama &&
                                                item.customerNama != '-'
                                            ? 'Akun: ${item.customerNama}'
                                            : item.pengirimNoHp,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Penerima
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.penerimaNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.penerimaNoHp,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 4. Alamat Asal & Tujuan
                                DataCell(
                                  SizedBox(
                                    width: 210,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Asal: ${item.pengirimKota}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tujuan: ${item.penerimaKota} (${item.penerimaAlamat})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 5. Jenis Layanan & Berat Paket
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: isDark ? 0.2 : 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.serviceNama,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatWeight(item.totalBeratGram),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 6. Biaya Pengiriman, Metode & Status Pembayaran
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AdminCurrencyFormatter.formatRupiah(
                                          item.totalBiaya,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${item.metodePembayaran.toUpperCase()} • ',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                          Text(
                                            AdminStatusHelper
                                                .getPaymentStatusLabel(
                                              item.statusPembayaran,
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: payStatusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 7. Kurir yang Ditugaskan
                                DataCell(
                                  item.hasCourierAssigned
                                      ? InkWell(
                                          onTap: item.isTerminalStatus
                                              ? null
                                              : () =>
                                                  widget.onAssignCourier(item),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.two_wheeler_rounded,
                                                    size: 14,
                                                    color: AppColors.info,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.courierNama,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.courierCode != null)
                                                Text(
                                                  '${item.courierCode} • ${item.courierNoHp ?? "-"}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondaryLight,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : TextButton.icon(
                                          onPressed: item.isTerminalStatus
                                              ? null
                                              : () =>
                                                  widget.onAssignCourier(item),
                                          icon: const Icon(
                                            Icons.person_add_alt_1_rounded,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Tugaskan Kurir',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                ),

                                // 8. Status Pengiriman
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      item.statusNama,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),

                                // 9. Tanggal Pembuatan Pesanan
                                DataCell(
                                  Text(
                                    AdminDateFormatter.formatDateTime(
                                      item.createdAt,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),

                                // 10. Aksi Operasional
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () =>
                                            widget.onViewDetail(item.id),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Detail',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (item.isWaitingConfirmation) ...[
                                        const SizedBox(width: 6),
                                        FilledButton(
                                          onPressed: widget.isActionInProgress
                                              ? null
                                              : () =>
                                                  widget.onConfirmOrder(item),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Konfirmasi',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (!item.isTerminalStatus) ...[
                                        const SizedBox(width: 6),
                                        IconButton(
                                          onPressed: widget.isActionInProgress
                                              ? null
                                              : () =>
                                                  widget.onAssignCourier(item),
                                          icon: const Icon(
                                            Icons.assignment_ind_rounded,
                                            size: 18,
                                          ),
                                          tooltip: item.hasCourierAssigned
                                              ? 'Ubah Penugasan Kurir'
                                              : 'Tugaskan Kurir',
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                      if (item.isFailedDelivery) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: widget.isActionInProgress
                                              ? null
                                              : () =>
                                                  widget.onHandleFailed(item),
                                          icon: const Icon(
                                            Icons.build_circle_outlined,
                                            size: 18,
                                            color: AppColors.error,
                                          ),
                                          tooltip: 'Tangani Pengiriman Gagal',
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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

          // Footer Paginasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${widget.deliveriesResult.currentPage} dari ${widget.deliveriesResult.totalPages} (Total ${widget.deliveriesResult.totalCount} pengiriman)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: widget.deliveriesResult.currentPage > 1
                          ? () => widget.onPageChanged(
                                widget.deliveriesResult.currentPage - 1,
                              )
                          : null,
                      tooltip: 'Halaman Sebelumnya',
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.deliveriesResult.currentPage}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: widget.deliveriesResult.currentPage <
                              widget.deliveriesResult.totalPages
                          ? () => widget.onPageChanged(
                                widget.deliveriesResult.currentPage + 1,
                              )
                          : null,
                      tooltip: 'Halaman Selanjutnya',
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
}

