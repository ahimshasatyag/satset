import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/admin_assignable_courier.dart';
import 'admin_searchable_dropdown.dart';

class DeliveryFilterBar extends StatefulWidget {
  final String searchQuery;
  final String statusFilter;
  final String paymentMethodFilter;
  final String paymentStatusFilter;
  final String serviceFilter;
  final String courierFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> serviceOptions;
  final List<AdminAssignableCourier> couriers;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates,
  })
  onFiltersChanged;
  final VoidCallback onResetFilters;

  const DeliveryFilterBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.paymentMethodFilter,
    required this.paymentStatusFilter,
    required this.serviceFilter,
    required this.courierFilter,
    this.startDate,
    this.endDate,
    required this.statusOptions,
    required this.serviceOptions,
    required this.couriers,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onResetFilters,
  });

  @override
  State<DeliveryFilterBar> createState() => _DeliveryFilterBarState();
}

class _DeliveryFilterBarState extends State<DeliveryFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant DeliveryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
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
      widget.onFiltersChanged(startDate: picked.start, endDate: picked.end);
    }
  }

  bool get _hasActiveFilters =>
      widget.searchQuery.isNotEmpty ||
      widget.statusFilter != 'ALL' ||
      widget.paymentMethodFilter != 'ALL' ||
      widget.paymentStatusFilter != 'ALL' ||
      widget.serviceFilter != 'ALL' ||
      widget.courierFilter != 'ALL' ||
      widget.startDate != null ||
      widget.endDate != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Pencarian (Nomor Resi, Barcode, Pengirim, Penerima)
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              onSubmitted: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari resi, barcode, pengirim, penerima...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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

          // 2. Filter Status Pengiriman
          AdminSearchableDropdown<String>(
            value: widget.statusFilter,
            width: 215,
            searchHintText: 'Cari status...',
            options: [
              const AdminDropdownOption(value: 'ALL', label: 'Semua Status'),
              ...widget.statusOptions.map((opt) {
                final code = (opt['kode'] ?? opt['id']).toString();
                final name = (opt['nama_status'] ?? code).toString();
                return AdminDropdownOption<String>(value: code, label: name);
              }),
            ],
            onChanged: (val) {
              widget.onFiltersChanged(statusFilter: val);
            },
          ),

          // 3. Filter Jenis Layanan
          AdminSearchableDropdown<String>(
            value: widget.serviceFilter,
            width: 195,
            searchHintText: 'Cari layanan...',
            options: [
              const AdminDropdownOption(value: 'ALL', label: 'Semua Layanan'),
              ...widget.serviceOptions.map((opt) {
                final code = (opt['kode'] ?? opt['id']).toString();
                final name = (opt['nama_layanan'] ?? code).toString();
                return AdminDropdownOption<String>(value: code, label: name);
              }),
            ],
            onChanged: (val) {
              widget.onFiltersChanged(serviceFilter: val);
            },
          ),

          // 4. Filter Metode Pembayaran
          AdminSearchableDropdown<String>(
            value: widget.paymentMethodFilter,
            width: 185,
            searchHintText: 'Cari metode bayar...',
            options: const [
              AdminDropdownOption(value: 'ALL', label: 'Metode Bayar'),
              AdminDropdownOption(value: 'TRANSFER', label: 'Transfer Bank'),
              AdminDropdownOption(value: 'QRIS', label: 'QRIS'),
              AdminDropdownOption(value: 'E_WALLET', label: 'E-Wallet'),
              AdminDropdownOption(value: 'COD', label: 'COD'),
            ],
            onChanged: (val) {
              widget.onFiltersChanged(paymentMethodFilter: val);
            },
          ),

          // 5. Filter Status Pembayaran
          AdminSearchableDropdown<String>(
            value: widget.paymentStatusFilter,
            width: 205,
            searchHintText: 'Cari status bayar...',
            options: const [
              AdminDropdownOption(value: 'ALL', label: 'Status Bayar'),
              AdminDropdownOption(value: 'PAID', label: 'Lunas (PAID)'),
              AdminDropdownOption(
                value: 'PENDING',
                label: 'Menunggu (PENDING)',
              ),
              AdminDropdownOption(value: 'COD', label: 'Bayar di Tempat (COD)'),
              AdminDropdownOption(value: 'FAILED', label: 'Gagal (FAILED)'),
            ],
            onChanged: (val) {
              widget.onFiltersChanged(paymentStatusFilter: val);
            },
          ),

          // 6. Filter Kurir
          AdminSearchableDropdown<String>(
            value: widget.courierFilter,
            width: 230,
            searchHintText: 'Cari nama / kode kurir...',
            options: [
              const AdminDropdownOption(value: 'ALL', label: 'Semua Kurir'),
              const AdminDropdownOption(
                value: 'UNASSIGNED',
                label: 'Belum Ditugaskan',
              ),
              ...widget.couriers.map((c) {
                return AdminDropdownOption<String>(
                  value: c.id.toString(),
                  label: '${c.namaLengkap} (${c.employeeCode})',
                );
              }),
            ],
            onChanged: (val) {
              widget.onFiltersChanged(courierFilter: val);
            },
          ),

          // 7. Filter Rentang Tanggal
          OutlinedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(
              widget.startDate != null && widget.endDate != null
                  ? '${AdminDateFormatter.formatShortDate(widget.startDate)} - ${AdminDateFormatter.formatShortDate(widget.endDate)}'
                  : 'Rentang Tanggal',
              style: AppTextStyles.labelSmall,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          if (widget.startDate != null)
            IconButton(
              onPressed: () => widget.onFiltersChanged(clearDates: true),
              icon: const Icon(Icons.event_busy_rounded, size: 18),
              tooltip: 'Hapus Filter Tanggal',
            ),

          // 8. Tombol Reset Semua Filter
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                widget.onResetFilters();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Reset Filter'),
            ),
        ],
      ),
    );
  }
}
