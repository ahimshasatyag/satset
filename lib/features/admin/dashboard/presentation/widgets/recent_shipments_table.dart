import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_shipment_table_item.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class RecentShipmentsTable extends StatefulWidget {
  final AdminShipmentsPaginatedResult shipmentsResult;
  final bool isLoading;
  final String searchQuery;
  final String selectedStatus;
  final String selectedService;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> serviceOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onServiceChanged;
  final void Function(DateTime? start, DateTime? end) onDateRangeChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSelectShipment;

  const RecentShipmentsTable({
    super.key,
    required this.shipmentsResult,
    required this.isLoading,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedService,
    this.startDate,
    this.endDate,
    required this.statusOptions,
    required this.serviceOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onServiceChanged,
    required this.onDateRangeChanged,
    required this.onPageChanged,
    required this.onSelectShipment,
  });

  @override
  State<RecentShipmentsTable> createState() => _RecentShipmentsTableState();
}

class _RecentShipmentsTableState extends State<RecentShipmentsTable> {
  late final TextEditingController _searchController;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant RecentShipmentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
    );

    if (picked != null) {
      widget.onDateRangeChanged(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.shipmentsResult.items;

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
          // Header & Filter Toolbar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Pengiriman Terbaru',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola dan pantau seluruh resi pengiriman SatSet Delivery',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (widget.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Controls: Search & Dropdowns
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search Bar
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: widget.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Cari no. resi / nama...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    widget.onSearchChanged('');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Filter Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.selectedStatus,
                          hint: const Text('Status'),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            const DropdownMenuItem(
                              value: 'ALL',
                              child: Text('Semua Status'),
                            ),
                            ...widget.statusOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['id']?.toString() ?? '',
                                child: Text(opt['nama_status']?.toString() ?? opt['kode']?.toString() ?? ''),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) widget.onStatusChanged(val);
                          },
                        ),
                      ),
                    ),

                    // Filter Layanan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.selectedService,
                          hint: const Text('Layanan'),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            const DropdownMenuItem(
                              value: 'ALL',
                              child: Text('Semua Layanan'),
                            ),
                            ...widget.serviceOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['id']?.toString() ?? '',
                                child: Text(opt['nama_layanan']?.toString() ?? opt['kode']?.toString() ?? ''),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) widget.onServiceChanged(val);
                          },
                        ),
                      ),
                    ),

                    // Filter Tanggal
                    OutlinedButton.icon(
                      onPressed: () => _pickDateRange(context),
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        widget.startDate != null && widget.endDate != null
                            ? '${AdminDateFormatter.formatShortDate(widget.startDate)} - ${AdminDateFormatter.formatShortDate(widget.endDate)}'
                            : 'Pilih Tanggal',
                        style: AppTextStyles.labelSmall,
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    if (widget.startDate != null)
                      IconButton(
                        onPressed: () => widget.onDateRangeChanged(null, null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Reset Tanggal',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Data Table
          if (items.isEmpty && !widget.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada data pengiriman yang sesuai filter.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          ),
                          horizontalMargin: 20,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Nomor Resi', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Pengirim', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Penerima', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Layanan', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Kurir SatSet', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status Terkini', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Biaya', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: items.map((item) {
                            final statusColor = AdminStatusHelper.getStatusColor(item.statusKode, isDark: isDark);
                            final statusBg = AdminStatusHelper.getStatusBgColor(item.statusKode, isDark: isDark);

                            return DataRow(
                              cells: [
                                // Resi
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.nomorResi,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Pengirim
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.pengirimNama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(item.pengirimKota, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                    ],
                                  ),
                                ),
                                // Penerima
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.penerimaNama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(item.penerimaKota, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                    ],
                                  ),
                                ),
                                // Layanan
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.serviceNama,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                // Kurir
                                DataCell(
                                  Text(
                                    item.courierNama,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.courierNama == 'Belum Ditugaskan'
                                          ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      fontStyle: item.courierNama == 'Belum Ditugaskan' ? FontStyle.italic : FontStyle.normal,
                                    ),
                                  ),
                                ),
                                // Status
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                                // Total Biaya
                                DataCell(
                                  Text(
                                    AdminCurrencyFormatter.formatRupiah(item.totalBiaya),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Tanggal
                                DataCell(
                                  Text(
                                    AdminDateFormatter.formatDateTime(item.createdAt),
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                ),
                                // Aksi
                                DataCell(
                                  FilledButton.tonal(
                                    onPressed: () => widget.onSelectShipment(item.id),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Detail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${widget.shipmentsResult.currentPage} dari ${widget.shipmentsResult.totalPages} (Total ${widget.shipmentsResult.totalCount} pengiriman)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: widget.shipmentsResult.currentPage > 1
                          ? () => widget.onPageChanged(widget.shipmentsResult.currentPage - 1)
                          : null,
                      tooltip: 'Halaman Sebelumnya',
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.shipmentsResult.currentPage}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: widget.shipmentsResult.currentPage < widget.shipmentsResult.totalPages
                          ? () => widget.onPageChanged(widget.shipmentsResult.currentPage + 1)
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

