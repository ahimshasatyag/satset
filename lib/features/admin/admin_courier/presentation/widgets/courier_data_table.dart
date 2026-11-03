import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_courier_item.dart';
import 'courier_filter_bar.dart';
import 'courier_skeleton.dart';

class CourierDataTable extends StatefulWidget {
  final AdminCouriersPaginatedResult couriersResult;
  final bool isLoading;
  final bool isActionInProgress;
  final String searchQuery;
  final String accountStatusFilter;
  final String activityStatusFilter;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? accountStatusFilter,
    String? activityStatusFilter,
  }) onFiltersChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onAddCourierPressed;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onViewDetail;
  final ValueChanged<AdminCourierItem> onEditCourier;
  final ValueChanged<AdminCourierItem> onToggleStatus;

  const CourierDataTable({
    super.key,
    required this.couriersResult,
    required this.isLoading,
    this.isActionInProgress = false,
    required this.searchQuery,
    required this.accountStatusFilter,
    required this.activityStatusFilter,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onResetFilters,
    required this.onAddCourierPressed,
    required this.onPageChanged,
    required this.onViewDetail,
    required this.onEditCourier,
    required this.onToggleStatus,
  });

  @override
  State<CourierDataTable> createState() => _CourierDataTableState();
}

class _CourierDataTableState extends State<CourierDataTable> {
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

  Widget _buildAvatar(AdminCourierItem item, bool isDark) {
    final initial = item.namaLengkap.trim().isNotEmpty
        ? item.namaLengkap.trim()[0].toUpperCase()
        : 'K';

    if (item.fotoUrl != null && item.fotoUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 19,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(item.fotoUrl!.trim()),
        onBackgroundImageError: (_, _) {},
        child: Text(
          initial,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 19,
      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
      child: Text(
        initial,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.couriersResult.items;

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
          // Header Tabel Kurir + Tombol Tambah Kurir Baru (sebelah kanan horizontal) + Filter Bar terpadu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Kurir SatSet Delivery (m_employee)',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Menampilkan ${items.length} dari ${widget.couriersResult.totalCount} kurir terdaftar (id_users_role = 2)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading || widget.isActionInProgress) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 14),
                        ],
                        FilledButton.icon(
                          onPressed: widget.onAddCourierPressed,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: const Text('Tambah Kurir Baru'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CourierFilterBar(
                  searchQuery: widget.searchQuery,
                  accountStatusFilter: widget.accountStatusFilter,
                  activityStatusFilter: widget.activityStatusFilter,
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
                  onSearchChanged: widget.onSearchChanged,
                  onFiltersChanged: widget.onFiltersChanged,
                  onSortChanged: widget.onSortChanged,
                  onResetFilters: widget.onResetFilters,
                  onAddCourierPressed: widget.onAddCourierPressed,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          if (widget.isLoading)
            const CourierTableRowsSkeleton(rowCount: 6)
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 52,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak Ada Data Kurir',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belum ada data kurir (id_users_role = 2) yang sesuai dengan pencarian atau filter yang dipilih.',
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
                          dataRowMinHeight: 64,
                          dataRowMaxHeight: 78,
                          horizontalMargin: 20,
                          columnSpacing: 22,
                          columns: [
                            DataColumn(
                              label: _buildSortableHeader(
                                'Profil & Identitas Employee',
                                'nama_lengkap',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Kontak & Alamat',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status Akun',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Status Aktivitas & Tugas',
                                'active_tasks',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Riwayat Pengiriman',
                                'total_handled',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Lokasi GPS Terakhir',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Tanggal Bergabung',
                                'created_at',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Tindakan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: items.map((c) {
                            final loc = c.lastLocation;
                            final hasGps = loc != null && c.hasActiveAssignment;

                            return DataRow(
                              cells: [
                                // 1. Profil & Identitas Employee
                                DataCell(
                                  InkWell(
                                    onTap: () => widget.onViewDetail(c.id),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildAvatar(c, isDark),
                                        const SizedBox(width: 10),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.namaLengkap,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.tertiary
                                                        .withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      4,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Kode: ${c.employeeCode}',
                                                    style: AppTextStyles
                                                        .labelSmall
                                                        .copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'ID #${c.id} • Role ${c.idUsersRole}',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
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
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 2. Kontak & Alamat
                                DataCell(
                                  SizedBox(
                                    width: 210,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          c.noHp,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        if (c.alamatLengkap != null &&
                                            c.alamatLengkap!.isNotEmpty)
                                          Text(
                                            c.alamatLengkap!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 3. Status Akun
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (c.isActive
                                              ? AppColors.success
                                              : AppColors.error)
                                          .withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (c.isActive
                                                ? AppColors.success
                                                : AppColors.error)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      c.isActive ? 'Aktif' : 'Nonaktif',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: c.isActive
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // 4. Status Aktivitas & Tugas
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (c.hasActiveAssignment
                                              ? AppColors.secondary
                                              : AppColors.tertiary)
                                          .withValues(
                                        alpha: isDark ? 0.2 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          c.hasActiveAssignment
                                              ? Icons.local_shipping_rounded
                                              : Icons.pause_circle_outline_rounded,
                                          size: 14,
                                          color: c.hasActiveAssignment
                                              ? AppColors.secondary
                                              : AppColors.tertiary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          c.activityStatusLabel,
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: c.hasActiveAssignment
                                                ? AppColors.secondary
                                                : (isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.tertiary),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 5. Riwayat Pengiriman (Total, Berhasil, Gagal)
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total: ${c.totalHandledCount} Paket',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Berhasil: ${c.deliveredCount} • Gagal: ${c.failedCount}',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 6. Lokasi GPS Terakhir (t_shipment_locations)
                                DataCell(
                                  hasGps
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.my_location_rounded,
                                                  size: 13,
                                                  color: AppColors.success,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              AdminDateFormatter.formatDateTime(
                                                loc.recordedAt,
                                              ),
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                fontSize: 10,
                                                color: isDark
                                                    ? AppColors
                                                        .textSecondaryDark
                                                    : AppColors
                                                        .textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          c.hasActiveAssignment
                                              ? 'Menunggu sinyal GPS...'
                                              : 'Tidak sedang bertugas',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                ),

                                // 7. Tanggal Bergabung
                                DataCell(
                                  Text(
                                    AdminDateFormatter.formatDateTime(
                                      c.createdAt,
                                    ),
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ),

                                // 8. Tindakan Admin
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip:
                                            'Lihat Detail, Penugasan & Lokasi Kurir',
                                        onPressed: () =>
                                            widget.onViewDetail(c.id),
                                        icon: const Icon(
                                          Icons.visibility_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit Profil Kurir',
                                        onPressed: () =>
                                            widget.onEditCourier(c),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: c.isActive
                                            ? 'Nonaktifkan Akun Kurir'
                                            : 'Aktifkan Akun Kurir',
                                        onPressed: () =>
                                            widget.onToggleStatus(c),
                                        icon: Icon(
                                          c.isActive
                                              ? Icons.toggle_on_rounded
                                              : Icons.toggle_off_rounded,
                                          size: 26,
                                          color: c.isActive
                                              ? AppColors.success
                                              : Colors.grey,
                                        ),
                                      ),
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

          // Footer Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${widget.couriersResult.currentPage} dari ${widget.couriersResult.totalPages} '
                  '(Total ${widget.couriersResult.totalCount} kurir)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.couriersResult.currentPage > 1
                          ? () => widget.onPageChanged(
                                widget.couriersResult.currentPage - 1,
                              )
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Halaman Sebelumnya',
                    ),
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
                        '${widget.couriersResult.currentPage}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.couriersResult.currentPage <
                              widget.couriersResult.totalPages
                          ? () => widget.onPageChanged(
                                widget.couriersResult.currentPage + 1,
                              )
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Halaman Berikutnya',
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

