import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_customer_item.dart';
import 'customer_filter_bar.dart';
import 'customer_skeleton.dart';

class CustomerDataTable extends StatefulWidget {
  final AdminCustomersPaginatedResult customersResult;
  final bool isLoading;
  final bool isActionInProgress;
  final String searchQuery;
  final String verificationFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? verificationFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates,
  }) onFiltersChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onViewDetail;
  final ValueChanged<AdminCustomerItem> onEditCustomer;
  final ValueChanged<AdminCustomerItem> onToggleVerification;

  const CustomerDataTable({
    super.key,
    required this.customersResult,
    required this.isLoading,
    this.isActionInProgress = false,
    required this.searchQuery,
    required this.verificationFilter,
    this.startDate,
    this.endDate,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onResetFilters,
    required this.onPageChanged,
    required this.onViewDetail,
    required this.onEditCustomer,
    required this.onToggleVerification,
  });

  @override
  State<CustomerDataTable> createState() => _CustomerDataTableState();
}

class _CustomerDataTableState extends State<CustomerDataTable> {
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

  Widget _buildAvatar(AdminCustomerItem item) {
    final initial = item.namaLengkap.trim().isNotEmpty
        ? item.namaLengkap.trim()[0].toUpperCase()
        : 'C';

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
    final items = widget.customersResult.items;

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
          // Header Tabel + Filter Bar Terpadu dalam 1 Container
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
                          'Daftar Pelanggan SatSet Delivery (m_users)',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Menampilkan ${items.length} dari ${widget.customersResult.totalCount} customer terdaftar (id_users_role = 3)',
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
                const SizedBox(height: 16),
                CustomerFilterBar(
                  searchQuery: widget.searchQuery,
                  verificationFilter: widget.verificationFilter,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
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

          if (widget.isLoading)
            const CustomerTableRowsSkeleton(rowCount: 6)
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 52,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak Ada Data Customer',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belum ada data customer pada m_users yang sesuai dengan pencarian atau filter yang dipilih.',
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
                                'Profil Customer',
                                'nama_lengkap',
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Email & Nomor Telepon',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status Verifikasi',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Alamat Utama & Wilayah',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Aktivitas Pengiriman',
                                'total_shipments',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Total Transaksi',
                                'total_amount',
                              ),
                            ),
                            DataColumn(
                              label: _buildSortableHeader(
                                'Tanggal Registrasi',
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
                            return DataRow(
                              cells: [
                                // 1. Profil Customer
                                DataCell(
                                  InkWell(
                                    onTap: () => widget.onViewDetail(c.id),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildAvatar(c),
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
                                            Text(
                                              'ID #${c.id} • Role ${c.idUsersRole} (Customer)'
                                              '${c.googleId != null ? " • Google Auth" : ""}',
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 2. Email & Nomor Telepon
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.email,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.noHp,
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Status Verifikasi Email
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (c.emailVerified
                                              ? AppColors.success
                                              : AppColors.warning)
                                          .withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (c.emailVerified
                                                ? AppColors.success
                                                : AppColors.warning)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          c.emailVerified
                                              ? Icons.verified_rounded
                                              : Icons
                                                  .mark_email_unread_rounded,
                                          size: 13,
                                          color: c.emailVerified
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.emailVerified
                                              ? 'Terverifikasi'
                                              : 'Belum Verifikasi',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: c.emailVerified
                                                ? AppColors.success
                                                : AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 4. Alamat Utama & Wilayah
                                DataCell(
                                  SizedBox(
                                    width: 225,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.alamatLengkap ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.formattedWilayahSummary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                ),

                                // 5. Aktivitas Pengiriman
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total: ${c.totalShipmentsCount} Paket',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Selesai: ${c.deliveredShipmentsCount} • Proses: ${c.ongoingShipmentsCount} • Gagal: ${c.failedShipmentsCount}',
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

                                // 6. Total Transaksi Pembayaran
                                DataCell(
                                  Text(
                                    AdminCurrencyFormatter.formatRupiah(
                                      c.totalTransactionAmount,
                                    ),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),

                                // 7. Tanggal Registrasi
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
                                            'Lihat Detail, Alamat & Riwayat Pengiriman Customer',
                                        onPressed: () =>
                                            widget.onViewDetail(c.id),
                                        icon: const Icon(
                                          Icons.visibility_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip:
                                            'Edit Profil & Wilayah Customer',
                                        onPressed: () =>
                                            widget.onEditCustomer(c),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: c.emailVerified
                                            ? 'Cabut Status Verifikasi Email'
                                            : 'Tandai Email Terverifikasi',
                                        onPressed: () =>
                                            widget.onToggleVerification(c),
                                        icon: Icon(
                                          c.emailVerified
                                              ? Icons.verified_user_rounded
                                              : Icons
                                                  .mark_email_read_outlined,
                                          size: 19,
                                          color: c.emailVerified
                                              ? AppColors.success
                                              : AppColors.warning,
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
                  'Halaman ${widget.customersResult.currentPage} dari ${widget.customersResult.totalPages} '
                  '(Total ${widget.customersResult.totalCount} customer)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.customersResult.currentPage > 1
                          ? () => widget.onPageChanged(
                                widget.customersResult.currentPage - 1,
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
                        '${widget.customersResult.currentPage}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.customersResult.currentPage <
                              widget.customersResult.totalPages
                          ? () => widget.onPageChanged(
                                widget.customersResult.currentPage + 1,
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

