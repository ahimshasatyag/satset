import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/shared/theme/theme.dart';

class CourierFilterBar extends StatefulWidget {
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

  const CourierFilterBar({
    super.key,
    required this.searchQuery,
    required this.accountStatusFilter,
    required this.activityStatusFilter,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onResetFilters,
  });

  @override
  State<CourierFilterBar> createState() => _CourierFilterBarState();
}

class _CourierFilterBarState extends State<CourierFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant CourierFilterBar oldWidget) {
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
      widget.searchQuery.isNotEmpty ||
      widget.accountStatusFilter != 'ALL' ||
      widget.activityStatusFilter != 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. Pencarian nama, email, no_hp, atau kode pegawai (employee_code)
        SizedBox(
          width: 290,
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            onSubmitted: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama, email, no. HP, atau kode kurir...',
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

        // 2. Filter Status Akun (m_employee.is_active)
        AdminSearchableDropdown<String>(
          value: widget.accountStatusFilter,
          width: 195,
          searchHintText: 'Cari status akun...',
          options: const [
            AdminDropdownOption(
              value: 'ALL',
              label: 'Semua Status Akun',
            ),
            AdminDropdownOption(
              value: 'ACTIVE',
              label: 'Akun Aktif',
            ),
            AdminDropdownOption(
              value: 'INACTIVE',
              label: 'Akun Tidak Aktif',
            ),
          ],
          onChanged: (val) {
            widget.onFiltersChanged(accountStatusFilter: val);
          },
        ),

        // 3. Filter Status Aktivitas Penugasan (t_shipment_assignments)
        AdminSearchableDropdown<String>(
          value: widget.activityStatusFilter,
          width: 225,
          searchHintText: 'Cari status aktivitas...',
          options: const [
            AdminDropdownOption(
              value: 'ALL',
              label: 'Semua Aktivitas Tugas',
            ),
            AdminDropdownOption(
              value: 'ON_TASK',
              label: 'Sedang Memiliki Tugas',
            ),
            AdminDropdownOption(
              value: 'STANDBY',
              label: 'Siap Ditugaskan (Standby)',
            ),
            AdminDropdownOption(
              value: 'UNASSIGNED',
              label: 'Belum Memiliki Penugasan',
            ),
          ],
          onChanged: (val) {
            widget.onFiltersChanged(activityStatusFilter: val);
          },
        ),

        // 4. Pengurutan berdasarkan Nama, Tanggal Bergabung, atau Beban Tugas
        AdminSearchableDropdown<String>(
          value: widget.sortColumn,
          width: 215,
          searchHintText: 'Cari urutan...',
          options: const [
            AdminDropdownOption(
              value: 'created_at',
              label: 'Urut: Tanggal Bergabung',
            ),
            AdminDropdownOption(
              value: 'nama_lengkap',
              label: 'Urut: Nama Lengkap',
            ),
            AdminDropdownOption(
              value: 'employee_code',
              label: 'Urut: Kode Pegawai',
            ),
            AdminDropdownOption(
              value: 'active_tasks',
              label: 'Urut: Beban Tugas Aktif',
            ),
            AdminDropdownOption(
              value: 'total_handled',
              label: 'Urut: Total Ditangani',
            ),
          ],
          onChanged: widget.onSortChanged,
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
