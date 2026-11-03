import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';

class ReportFilterPanel extends StatelessWidget {
  final AdminReportFilter filter;
  final AdminReportFilterReferences references;
  final String? dateValidationError;
  final void Function(DateTime? startDate, DateTime? endDate)
  onDateRangeChanged;
  final void Function({
    String? shipmentStatusCode,
    String? serviceTypeCode,
    String? paymentMethod,
    String? paymentStatus,
    int? courierId,
    bool clearCourierId,
  })
  onFilterUpdated;
  final VoidCallback onResetFilters;

  const ReportFilterPanel({
    super.key,
    required this.filter,
    required this.references,
    this.dateValidationError,
    required this.onDateRangeChanged,
    required this.onFilterUpdated,
    required this.onResetFilters,
  });

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih Tanggal Mulai Laporan',
    );
    if (picked != null) {
      onDateRangeChanged(picked, filter.endDate);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.endDate ?? filter.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih Tanggal Akhir Laporan',
    );
    if (picked != null) {
      onDateRangeChanged(filter.startDate, picked);
    }
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case 'TODAY':
        onDateRangeChanged(today, today);
        break;
      case 'LAST_7':
        onDateRangeChanged(today.subtract(const Duration(days: 6)), today);
        break;
      case 'LAST_30':
        onDateRangeChanged(today.subtract(const Duration(days: 29)), today);
        break;
      case 'THIS_MONTH':
        onDateRangeChanged(DateTime(now.year, now.month, 1), today);
        break;
      case 'ALL':
      default:
        onDateRangeChanged(null, null);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusOptions = <AdminDropdownOption<String>>[
      const AdminDropdownOption(value: 'ALL', label: 'Semua Status Pengiriman'),
      ...references.shipmentStatuses.map(
        (s) => AdminDropdownOption(
          value: s.code,
          label: '${s.label} (${s.code})',
        ),
      ),
    ];

    final serviceOptions = <AdminDropdownOption<String>>[
      const AdminDropdownOption(value: 'ALL', label: 'Semua Jenis Layanan'),
      ...references.serviceTypes.map(
        (s) => AdminDropdownOption(value: s.code, label: s.label),
      ),
    ];

    const paymentMethodOptions = <AdminDropdownOption<String>>[
      AdminDropdownOption(value: 'ALL', label: 'Semua Metode Pembayaran'),
      AdminDropdownOption(
        value: 'TRANSFER',
        label: 'Transfer (Payment Gateway)',
      ),
      AdminDropdownOption(value: 'COD', label: 'Cash on Delivery (COD)'),
    ];

    const paymentStatusOptions = <AdminDropdownOption<String>>[
      AdminDropdownOption(value: 'ALL', label: 'Semua Status Pembayaran'),
      AdminDropdownOption(value: 'PAID', label: 'Berhasil / Lunas (PAID)'),
      AdminDropdownOption(
        value: 'PENDING',
        label: 'Menunggu Pembayaran (PENDING)',
      ),
      AdminDropdownOption(value: 'FAILED', label: 'Gagal (FAILED)'),
      AdminDropdownOption(value: 'EXPIRED', label: 'Kedaluwarsa (EXPIRED)'),
    ];

    final courierOptions = <AdminDropdownOption<String>>[
      const AdminDropdownOption(value: 'ALL', label: 'Semua Kurir Bertugas'),
      ...references.couriers.map(
        (c) => AdminDropdownOption(value: c.id, label: c.label),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baris 1: Rentang Tanggal & Preset Cepat
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.date_range_rounded, size: 18),
                  Text(
                    'Rentang Tanggal:',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickStartDate(context),
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(
                      filter.startDate != null
                          ? 'Dari: ${AdminDateFormatter.formatShortDate(filter.startDate)}'
                          : 'Tanggal Mulai',
                    ),
                  ),
                  const Text('—'),
                  OutlinedButton.icon(
                    onPressed: () => _pickEndDate(context),
                    icon: const Icon(Icons.event_outlined, size: 15),
                    label: Text(
                      filter.endDate != null
                          ? 'Sampai: ${AdminDateFormatter.formatShortDate(filter.endDate)}'
                          : 'Tanggal Akhir',
                    ),
                  ),
                  if (filter.startDate != null || filter.endDate != null)
                    IconButton(
                      tooltip: 'Hapus Filter Tanggal',
                      onPressed: () => onDateRangeChanged(null, null),
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _PresetChip(
                    label: 'Semua Waktu',
                    isSelected:
                        filter.startDate == null && filter.endDate == null,
                    onTap: () => _applyDatePreset('ALL'),
                  ),
                  _PresetChip(
                    label: 'Hari Ini',
                    isSelected: false,
                    onTap: () => _applyDatePreset('TODAY'),
                  ),
                  _PresetChip(
                    label: '7 Hari',
                    isSelected: false,
                    onTap: () => _applyDatePreset('LAST_7'),
                  ),
                  _PresetChip(
                    label: '30 Hari',
                    isSelected: false,
                    onTap: () => _applyDatePreset('LAST_30'),
                  ),
                  _PresetChip(
                    label: 'Bulan Ini',
                    isSelected: false,
                    onTap: () => _applyDatePreset('THIS_MONTH'),
                  ),
                ],
              ),
            ],
          ),

          if (dateValidationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateValidationError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Baris 2: Dropdown Filter Multi-Dimensi
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminSearchableDropdown<String>(
                value: filter.shipmentStatusCode ?? 'ALL',
                width: 220,
                searchHintText: 'Cari status pengiriman...',
                options: statusOptions,
                onChanged: (val) => onFilterUpdated(
                  shipmentStatusCode: val == 'ALL' ? '' : val,
                ),
              ),
              AdminSearchableDropdown<String>(
                value: filter.serviceTypeCode ?? 'ALL',
                width: 205,
                searchHintText: 'Cari jenis layanan...',
                options: serviceOptions,
                onChanged: (val) => onFilterUpdated(
                  serviceTypeCode: val == 'ALL' ? '' : val,
                ),
              ),
              AdminSearchableDropdown<String>(
                value: filter.paymentMethod ?? 'ALL',
                width: 215,
                searchHintText: 'Cari metode bayar...',
                options: paymentMethodOptions,
                onChanged: (val) => onFilterUpdated(
                  paymentMethod: val == 'ALL' ? '' : val,
                ),
              ),
              AdminSearchableDropdown<String>(
                value: filter.paymentStatus ?? 'ALL',
                width: 215,
                searchHintText: 'Cari status bayar...',
                options: paymentStatusOptions,
                onChanged: (val) => onFilterUpdated(
                  paymentStatus: val == 'ALL' ? '' : val,
                ),
              ),
              AdminSearchableDropdown<String>(
                value: filter.courierId?.toString() ?? 'ALL',
                width: 225,
                searchHintText: 'Cari nama / kode kurir...',
                options: courierOptions,
                onChanged: (val) {
                  if (val == 'ALL' || val.isEmpty) {
                    onFilterUpdated(clearCourierId: true);
                  } else {
                    final parsed = int.tryParse(val);
                    onFilterUpdated(courierId: parsed);
                  }
                },
              ),
              if (filter.hasActiveFilters)
                TextButton.icon(
                  onPressed: onResetFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
                  label: const Text('Reset Filter'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
