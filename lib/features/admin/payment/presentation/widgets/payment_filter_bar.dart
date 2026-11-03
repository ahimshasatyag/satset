import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_item.dart';

class PaymentFilterBar extends StatefulWidget {
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
  final List<AdminBankReference> bankReferences;
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

  const PaymentFilterBar({
    super.key,
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
    this.bankReferences = const [],
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onResetFilters,
  });

  @override
  State<PaymentFilterBar> createState() => _PaymentFilterBarState();
}

class _PaymentFilterBarState extends State<PaymentFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _minAmountController = TextEditingController(
      text: widget.minAmount != null ? widget.minAmount!.toInt().toString() : '',
    );
    _maxAmountController = TextEditingController(
      text: widget.maxAmount != null ? widget.maxAmount!.toInt().toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant PaymentFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
    final nextMin =
        widget.minAmount != null ? widget.minAmount!.toInt().toString() : '';
    if (nextMin != _minAmountController.text) {
      _minAmountController.text = nextMin;
    }
    final nextMax =
        widget.maxAmount != null ? widget.maxAmount!.toInt().toString() : '';
    if (nextMax != _maxAmountController.text) {
      _maxAmountController.text = nextMax;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      widget.searchQuery.isNotEmpty ||
      widget.methodFilter != 'ALL' ||
      widget.statusFilter != 'ALL' ||
      widget.jenisBankFilter != 'ALL' ||
      widget.startDate != null ||
      widget.endDate != null ||
      widget.minAmount != null ||
      widget.maxAmount != null;

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = (widget.startDate != null && widget.endDate != null)
        ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
      helpText: 'Pilih Rentang Tanggal Transaksi Pembayaran',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );

    if (picked != null) {
      widget.onFiltersChanged(
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  void _applyAmountRange() {
    final minVal = num.tryParse(
      _minAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final maxVal = num.tryParse(
      _maxAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    widget.onFiltersChanged(
      minAmount: minVal,
      maxAmount: maxVal,
      clearAmounts: minVal == null && maxVal == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Daftar unik m_jenis_bank untuk dropdown filter bank
    final uniqueBanks = <String, String>{};
    for (final b in widget.bankReferences) {
      if (b.namaJenisBank.isNotEmpty) {
        uniqueBanks[b.namaJenisBank.toUpperCase()] =
            'Bank ${b.namaJenisBank} (${b.nomorRekening})';
      }
    }

    final bankDropdownOptions = <AdminDropdownOption<String>>[
      const AdminDropdownOption(
        value: 'ALL',
        label: 'Semua Bank / Channel (m_jenis_bank)',
      ),
      ...uniqueBanks.entries.map(
        (e) => AdminDropdownOption(value: e.key, label: e.value),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 1. Pencarian: nomor resi, ID transaksi, nama customer, atau referensi gateway
            SizedBox(
              width: 310,
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText:
                      'Cari no. resi, ID pembayaran, customer, atau ref gateway...',
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
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Filter Metode Pembayaran
            AdminSearchableDropdown<String>(
              width: 205,
              value: widget.methodFilter,
              hintText: 'Metode Pembayaran',
              searchHintText: 'Cari metode...',
              options: const [
                AdminDropdownOption(value: 'ALL', label: 'Semua Metode'),
                AdminDropdownOption(
                  value: 'TRANSFER',
                  label: 'Transfer / Gateway',
                ),
                AdminDropdownOption(
                  value: 'COD',
                  label: 'Cash on Delivery (COD)',
                ),
                AdminDropdownOption(value: 'QRIS', label: 'QRIS'),
                AdminDropdownOption(
                  value: 'VIRTUAL_ACCOUNT',
                  label: 'Virtual Account',
                ),
              ],
              onChanged: (val) {
                widget.onFiltersChanged(methodFilter: val);
              },
            ),

            // 3. Filter Status Pembayaran Aktual
            AdminSearchableDropdown<String>(
              width: 205,
              value: widget.statusFilter,
              hintText: 'Status Pembayaran',
              searchHintText: 'Cari status...',
              options: const [
                AdminDropdownOption(value: 'ALL', label: 'Semua Status'),
                AdminDropdownOption(
                  value: 'PENDING',
                  label: 'Pending (Menunggu)',
                ),
                AdminDropdownOption(value: 'PAID', label: 'Paid (Lunas)'),
                AdminDropdownOption(value: 'FAILED', label: 'Failed (Gagal)'),
                AdminDropdownOption(
                  value: 'EXPIRED',
                  label: 'Expired (Kedaluwarsa)',
                ),
                AdminDropdownOption(value: 'COD', label: 'Status COD'),
              ],
              onChanged: (val) {
                widget.onFiltersChanged(statusFilter: val);
              },
            ),

            // 4. Filter Jenis Bank (m_jenis_bank & m_bank)
            AdminSearchableDropdown<String>(
              width: 225,
              value: bankDropdownOptions
                      .any((i) => i.value == widget.jenisBankFilter)
                  ? widget.jenisBankFilter
                  : 'ALL',
              hintText: 'Semua Bank',
              searchHintText: 'Cari bank...',
              options: bankDropdownOptions,
              onChanged: (val) {
                widget.onFiltersChanged(jenisBankFilter: val);
              },
            ),

            // 5. Filter Rentang Tanggal Transaksi
            InkWell(
              onTap: () => _pickDateRange(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: (widget.startDate != null && widget.endDate != null)
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (widget.startDate != null && widget.endDate != null)
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color:
                          (widget.startDate != null && widget.endDate != null)
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (widget.startDate != null && widget.endDate != null)
                          ? '${AdminDateFormatter.formatShortDate(widget.startDate)} - ${AdminDateFormatter.formatShortDate(widget.endDate)}'
                          : 'Rentang Tanggal',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight:
                            (widget.startDate != null && widget.endDate != null)
                                ? FontWeight.bold
                                : FontWeight.w500,
                        color:
                            (widget.startDate != null && widget.endDate != null)
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (widget.startDate != null && widget.endDate != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () =>
                            widget.onFiltersChanged(clearDates: true),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 6. Filter Rentang Nominal Pembayaran
            SizedBox(
              width: 130,
              height: 40,
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _applyAmountRange(),
                onEditingComplete: _applyAmountRange,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Nominal Min (Rp)',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              height: 40,
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _applyAmountRange(),
                onEditingComplete: _applyAmountRange,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Nominal Maks (Rp)',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ),

            // 7. Pengurutan Kolom
            AdminSearchableDropdown<String>(
              width: 215,
              value: widget.sortColumn,
              hintText: 'Urutkan',
              searchHintText: 'Cari urutan...',
              options: const [
                AdminDropdownOption(
                  value: 'created_at',
                  label: 'Urut: Waktu Transaksi',
                ),
                AdminDropdownOption(
                  value: 'jumlah_bayar',
                  label: 'Urut: Nominal Pembayaran',
                ),
                AdminDropdownOption(
                  value: 'paid_at',
                  label: 'Urut: Waktu Lunas',
                ),
                AdminDropdownOption(
                  value: 'nomor_pembayaran',
                  label: 'Urut: ID Pembayaran',
                ),
                AdminDropdownOption(
                  value: 'nomor_resi',
                  label: 'Urut: Nomor Resi',
                ),
                AdminDropdownOption(
                  value: 'customer_nama',
                  label: 'Urut: Nama Customer',
                ),
              ],
              onChanged: (val) {
                widget.onSortChanged(val);
              },
            ),

            // 8. Tombol Reset Filter
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _minAmountController.clear();
                  _maxAmountController.clear();
                  widget.onResetFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Reset Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
