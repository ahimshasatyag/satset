import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';

class CustomerFilterBar extends StatefulWidget {
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

  const CustomerFilterBar({
    super.key,
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
  });

  @override
  State<CustomerFilterBar> createState() => _CustomerFilterBarState();
}

class _CustomerFilterBarState extends State<CustomerFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant CustomerFilterBar oldWidget) {
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
      widget.onFiltersChanged(
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  bool get _hasActiveFilters =>
      widget.searchQuery.isNotEmpty ||
      widget.verificationFilter != 'ALL' ||
      widget.startDate != null ||
      widget.endDate != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. Pencarian nama lengkap, email, atau nomor telepon
        SizedBox(
          width: 290,
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            onSubmitted: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama lengkap, email, atau no. telepon...',
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
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),

        // 2. Filter Status Verifikasi Email (email_verified)
        AdminSearchableDropdown<String>(
          value: widget.verificationFilter,
          width: 215,
          searchHintText: 'Cari status verifikasi...',
          options: const [
            AdminDropdownOption(
              value: 'ALL',
              label: 'Semua Status Verifikasi',
            ),
            AdminDropdownOption(
              value: 'VERIFIED',
              label: 'Email Terverifikasi',
            ),
            AdminDropdownOption(
              value: 'UNVERIFIED',
              label: 'Belum Terverifikasi',
            ),
            AdminDropdownOption(
              value: 'NEW_30_DAYS',
              label: 'Registrasi 30 Hari Terakhir',
            ),
          ],
          onChanged: (val) {
            widget.onFiltersChanged(verificationFilter: val);
          },
        ),

        // 3. Pengurutan berdasarkan Nama, Tanggal Pendaftaran, atau Total Pengiriman
        AdminSearchableDropdown<String>(
          value: widget.sortColumn,
          width: 220,
          searchHintText: 'Cari urutan...',
          options: const [
            AdminDropdownOption(
              value: 'created_at',
              label: 'Urut: Tanggal Registrasi',
            ),
            AdminDropdownOption(
              value: 'nama_lengkap',
              label: 'Urut: Nama Lengkap',
            ),
            AdminDropdownOption(
              value: 'total_shipments',
              label: 'Urut: Total Pengiriman',
            ),
            AdminDropdownOption(
              value: 'total_amount',
              label: 'Urut: Total Transaksi',
            ),
          ],
          onChanged: widget.onSortChanged,
        ),

        // 4. Filter Rentang Tanggal Registrasi
        OutlinedButton.icon(
          onPressed: () => _selectDateRange(context),
          icon: const Icon(Icons.date_range_rounded, size: 16),
          label: Text(
            widget.startDate != null && widget.endDate != null
                ? '${AdminDateFormatter.formatShortDate(widget.startDate)} - ${AdminDateFormatter.formatShortDate(widget.endDate)}'
                : 'Tanggal Registrasi',
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
    );
  }
}

