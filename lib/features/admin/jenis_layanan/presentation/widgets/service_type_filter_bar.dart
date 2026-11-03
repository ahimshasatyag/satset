import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/shared/theme/theme.dart';

class ServiceTypeFilterBar extends StatefulWidget {
  final String searchQuery;
  final String statusFilter;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onResetFilters;

  const ServiceTypeFilterBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onResetFilters,
  });

  @override
  State<ServiceTypeFilterBar> createState() => _ServiceTypeFilterBarState();
}

class _ServiceTypeFilterBarState extends State<ServiceTypeFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ServiceTypeFilterBar oldWidget) {
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

  bool get _hasActiveFilters =>
      widget.searchQuery.isNotEmpty || widget.statusFilter != 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. Pencarian kode layanan, nama layanan, atau deskripsi
        SizedBox(
          width: 310,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'Cari kode layanan, nama layanan, atau deskripsi...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),

        // 2. Filter Status Layanan & Relasi Pengiriman
        AdminSearchableDropdown<String>(
          width: 235,
          value: widget.statusFilter,
          hintText: 'Status Layanan',
          searchHintText: 'Cari filter status...',
          options: const [
            AdminDropdownOption(
              value: 'ALL',
              label: 'Semua Status Layanan',
            ),
            AdminDropdownOption(
              value: 'ACTIVE',
              label: 'Layanan Aktif (is_active = true)',
            ),
            AdminDropdownOption(
              value: 'INACTIVE',
              label: 'Layanan Tidak Aktif (is_active = false)',
            ),
            AdminDropdownOption(
              value: 'USED',
              label: 'Sudah Digunakan di t_shipments',
            ),
            AdminDropdownOption(
              value: 'UNUSED',
              label: 'Belum Pernah Digunakan',
            ),
          ],
          onChanged: (val) {
            widget.onFilterChanged(val);
          },
        ),

        // 3. Pengurutan Kolom
        AdminSearchableDropdown<String>(
          width: 225,
          value: widget.sortColumn,
          hintText: 'Urutkan',
          searchHintText: 'Cari urutan...',
          options: const [
            AdminDropdownOption(
              value: 'id',
              label: 'Urut: ID Layanan',
            ),
            AdminDropdownOption(
              value: 'nama_layanan',
              label: 'Urut: Nama Layanan',
            ),
            AdminDropdownOption(
              value: 'kode',
              label: 'Urut: Kode Layanan',
            ),
            AdminDropdownOption(
              value: 'harga_dasar',
              label: 'Urut: Tarif Dasar / Kg',
            ),
            AdminDropdownOption(
              value: 'shipment_count',
              label: 'Urut: Jumlah Pengiriman',
            ),
            AdminDropdownOption(
              value: 'created_at',
              label: 'Urut: Tanggal Pembuatan',
            ),
          ],
          onChanged: (val) {
            widget.onSortChanged(val);
          },
        ),

        if (_hasActiveFilters)
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              widget.onResetFilters();
            },
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: const Text('Reset Filter'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
      ],
    );
  }
}

