import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_service_type_item.dart';
import 'service_type_filter_bar.dart';
import 'service_type_skeleton.dart';

class ServiceTypeDataTable extends StatefulWidget {
  final AdminServiceTypesPaginatedResult servicesResult;
  final bool isLoading;
  final bool isActionInProgress;
  final String searchQuery;
  final String statusFilter;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onAddServicePressed;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onViewDetail;
  final ValueChanged<AdminServiceTypeItem> onEditService;
  final ValueChanged<AdminServiceTypeItem> onToggleStatus;
  final ValueChanged<AdminServiceTypeItem> onDeleteService;

  const ServiceTypeDataTable({
    super.key,
    required this.servicesResult,
    required this.isLoading,
    this.isActionInProgress = false,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onResetFilters,
    required this.onAddServicePressed,
    required this.onPageChanged,
    required this.onViewDetail,
    required this.onEditService,
    required this.onToggleStatus,
    required this.onDeleteService,
  });

  @override
  State<ServiceTypeDataTable> createState() => _ServiceTypeDataTableState();
}

class _ServiceTypeDataTableState extends State<ServiceTypeDataTable> {
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
    final items = widget.servicesResult.items;

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
          // 1. Header Tabel + Tombol Tambah Jenis Layanan + Filter Bar Terpadu
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
                          'Daftar Master Jenis Layanan Pengiriman (m_service_types)',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Menampilkan ${items.length} dari ${widget.servicesResult.totalCount} jenis layanan terdaftar (Relasi penggunaan aktual pada t_shipments)',
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
                        FilledButton.icon(
                          onPressed: widget.onAddServicePressed,
                          icon: const Icon(Icons.add_box_rounded, size: 18),
                          label: const Text('Tambah Jenis Layanan Baru'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
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
                ServiceTypeFilterBar(
                  searchQuery: widget.searchQuery,
                  statusFilter: widget.statusFilter,
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
                  onSearchChanged: widget.onSearchChanged,
                  onFilterChanged: widget.onFilterChanged,
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
              child: ServiceTypeTableRowsSkeleton(rowCount: 5),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 52,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak Ada Jenis Layanan Ditemukan',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum ada jenis layanan pada m_service_types yang sesuai dengan pencarian atau filter aktif.',
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
                    columnSpacing: 24,
                    horizontalMargin: 20,
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? AppColors.backgroundDark.withValues(alpha: 0.6)
                          : AppColors.backgroundLight,
                    ),
                    columns: [
                      DataColumn(
                        label: _buildSortableHeader(
                          'ID & Kode Layanan',
                          'kode',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Nama Layanan & Deskripsi',
                          'nama_layanan',
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'Estimasi Waktu (SLA)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Aturan Tarif & Asuransi',
                          'harga_dasar',
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Penggunaan (t_shipments)',
                          'shipment_count',
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'Status Layanan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: _buildSortableHeader(
                          'Tanggal Dibuat',
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
                  'Halaman ${widget.servicesResult.currentPage} dari ${widget.servicesResult.totalPages} (Total ${widget.servicesResult.totalCount} jenis layanan)',
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
                      onPressed: widget.servicesResult.currentPage > 1
                          ? () => widget.onPageChanged(
                                widget.servicesResult.currentPage - 1,
                              )
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: const Text('Sebelumnya'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.servicesResult.currentPage <
                              widget.servicesResult.totalPages
                          ? () => widget.onPageChanged(
                                widget.servicesResult.currentPage + 1,
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

  DataRow _buildDataRow(AdminServiceTypeItem item, bool isDark) {
    final statusColor =
        item.isActive ? AppColors.success : AppColors.warning;

    return DataRow(
      cells: [
        // 1. ID & Kode Layanan
        DataCell(
          InkWell(
            onTap: () => widget.onViewDetail(item.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.kode,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID Layanan #${item.id}',
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
        ),

        // 2. Nama Layanan & Deskripsi
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.namaLayanan,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.deskripsi != null && item.deskripsi!.trim().isNotEmpty
                      ? item.deskripsi!
                      : 'Tidak ada deskripsi tambahan',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // 3. Estimasi Waktu Pengiriman (SLA)
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.formattedEstimasi,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Min: ${item.estimasiHariMin} hr • Maks: ${item.estimasiHariMax} hr',
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

        // 4. Aturan Tarif & Asuransi
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${AdminCurrencyFormatter.formatRupiah(item.baseTariffPerKg)} / Kg',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Asuransi: ${item.formattedInsuranceRate}',
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

        // 5. Penggunaan pada t_shipments
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isUsedInShipments
                        ? Icons.local_shipping_rounded
                        : Icons.inbox_outlined,
                    size: 14,
                    color: item.isUsedInShipments
                        ? AppColors.info
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.totalShipmentsCount} Pengiriman',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.isUsedInShipments
                    ? '${item.activeShipmentsCount} aktif • ${item.deliveredShipmentsCount} selesai'
                    : 'Belum digunakan transaksi',
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

        // 6. Status Layanan (is_active)
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
                  item.isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Text(
                  item.isActive ? 'Aktif' : 'Nonaktif',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 7. Tanggal Dibuat
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AdminDateFormatter.formatShortDate(item.createdAt),
                style: AppTextStyles.bodySmall,
              ),
              if (item.updatedAt != null)
                Text(
                  'Update: ${AdminDateFormatter.formatShortDate(item.updatedAt)}',
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
                message: 'Lihat Detail Layanan & Riwayat Pengiriman Terkait',
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
                message: 'Edit Informasi & Konfigurasi Jenis Layanan',
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.info,
                  ),
                  onPressed: widget.isActionInProgress
                      ? null
                      : () => widget.onEditService(item),
                ),
              ),
              Tooltip(
                message: item.isActive
                    ? 'Nonaktifkan Layanan (Sembunyikan dari pesanan baru)'
                    : 'Aktifkan Kembali Layanan',
                child: IconButton(
                  icon: Icon(
                    item.isActive
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_outlined,
                    size: 22,
                    color: item.isActive
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  onPressed: widget.isActionInProgress
                      ? null
                      : () => widget.onToggleStatus(item),
                ),
              ),
              Tooltip(
                message: item.canBeDeleted
                    ? 'Hapus Jenis Layanan (Belum digunakan transaksi)'
                    : 'Sudah digunakan pada ${item.totalShipmentsCount} pengiriman — Gunakan Nonaktifkan agar histori tidak rusak',
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: item.canBeDeleted
                        ? AppColors.error
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  onPressed: widget.isActionInProgress
                      ? null
                      : () => widget.onDeleteService(item),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

