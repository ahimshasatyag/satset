import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/buttons/custom_button.dart';
import '../../domain/entities/courier_task_history_item.dart';

/// Modal bottom sheet untuk konfigurasi filter riwayat tugas kurir
class CourierTaskHistoryFilterSheet extends StatefulWidget {
  final CourierHistoryTaskType selectedTaskType;
  final String selectedStatusCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? datePresetLabel;
  final Function({
    required CourierHistoryTaskType taskType,
    required String statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? presetLabel,
  }) onApply;
  final VoidCallback onReset;

  const CourierTaskHistoryFilterSheet({
    super.key,
    required this.selectedTaskType,
    required this.selectedStatusCode,
    this.startDate,
    this.endDate,
    this.datePresetLabel,
    required this.onApply,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required CourierHistoryTaskType selectedTaskType,
    required String selectedStatusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? datePresetLabel,
    required Function({
      required CourierHistoryTaskType taskType,
      required String statusCode,
      DateTime? startDate,
      DateTime? endDate,
      String? presetLabel,
    }) onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourierTaskHistoryFilterSheet(
        selectedTaskType: selectedTaskType,
        selectedStatusCode: selectedStatusCode,
        startDate: startDate,
        endDate: endDate,
        datePresetLabel: datePresetLabel,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<CourierTaskHistoryFilterSheet> createState() =>
      _CourierTaskHistoryFilterSheetState();
}

class _CourierTaskHistoryFilterSheetState
    extends State<CourierTaskHistoryFilterSheet> {
  late CourierHistoryTaskType _tempTaskType;
  late String _tempStatusCode;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  String? _tempPresetLabel;

  @override
  void initState() {
    super.initState();
    _tempTaskType = widget.selectedTaskType;
    _tempStatusCode = widget.selectedStatusCode;
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
    _tempPresetLabel = widget.datePresetLabel;
  }

  void _selectDatePreset(String label) {
    final now = DateTime.now();
    setState(() {
      _tempPresetLabel = label;
      switch (label) {
        case 'Hari Ini':
          _tempStartDate = DateTime(now.year, now.month, now.day);
          _tempEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case '7 Hari':
          _tempStartDate = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 7));
          _tempEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case '30 Hari':
          _tempStartDate = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 30));
          _tempEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Semua':
        default:
          _tempStartDate = null;
          _tempEndDate = null;
          _tempPresetLabel = null;
          break;
      }
    });
  }

  Future<void> _openCustomDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _tempStartDate != null && _tempEndDate != null
          ? DateTimeRange(start: _tempStartDate!, end: _tempEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tempStartDate = picked.start;
        _tempEndDate = picked.end;
        _tempPresetLabel = 'Kustom';
      });
    }
  }

  String _formatRange(DateTime start, DateTime end) {
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Riwayat Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempTaskType = CourierHistoryTaskType.all;
                    _tempStatusCode = 'ALL';
                    _tempStartDate = null;
                    _tempEndDate = null;
                    _tempPresetLabel = null;
                  });
                  widget.onReset();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Filter Rentang Tanggal
          const Text(
            'Rentang Tanggal',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChoiceChip(
                label: 'Semua Waktu',
                isSelected: _tempStartDate == null && _tempEndDate == null,
                onSelected: (_) => _selectDatePreset('Semua'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Hari Ini',
                isSelected: _tempPresetLabel == 'Hari Ini',
                onSelected: (_) => _selectDatePreset('Hari Ini'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: '7 Hari Terakhir',
                isSelected: _tempPresetLabel == '7 Hari',
                onSelected: (_) => _selectDatePreset('7 Hari'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: '30 Hari Terakhir',
                isSelected: _tempPresetLabel == '30 Hari',
                onSelected: (_) => _selectDatePreset('30 Hari'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: _tempPresetLabel == 'Kustom' &&
                        _tempStartDate != null &&
                        _tempEndDate != null
                    ? _formatRange(_tempStartDate!, _tempEndDate!)
                    : 'Pilih Tanggal...',
                icon: Icons.calendar_today_rounded,
                isSelected: _tempPresetLabel == 'Kustom',
                onSelected: (_) => _openCustomDateRangePicker(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Filter Jenis Tugas
          const Text(
            'Jenis Tugas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChoiceChip(
                label: 'Semua',
                isSelected: _tempTaskType == CourierHistoryTaskType.all,
                onSelected: (_) =>
                    setState(() => _tempTaskType = CourierHistoryTaskType.all),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Pengambilan (Pickup)',
                icon: Icons.archive_outlined,
                isSelected: _tempTaskType == CourierHistoryTaskType.pickup,
                onSelected: (_) =>
                    setState(() => _tempTaskType = CourierHistoryTaskType.pickup),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Pengantaran (Delivery)',
                icon: Icons.local_shipping_outlined,
                isSelected: _tempTaskType == CourierHistoryTaskType.delivery,
                onSelected: (_) =>
                    setState(() => _tempTaskType = CourierHistoryTaskType.delivery),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Filter Status Pengiriman
          const Text(
            'Status Akhir',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChoiceChip(
                label: 'Semua Status',
                isSelected: _tempStatusCode.toUpperCase() == 'ALL',
                onSelected: (_) => setState(() => _tempStatusCode = 'ALL'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Selesai (Terkirim)',
                isSelected: _tempStatusCode.toUpperCase() == 'DELIVERED',
                onSelected: (_) =>
                    setState(() => _tempStatusCode = 'DELIVERED'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Gagal Diantar',
                isSelected: _tempStatusCode.toUpperCase() == 'FAILED_DELIVERY',
                onSelected: (_) =>
                    setState(() => _tempStatusCode = 'FAILED_DELIVERY'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Dikembalikan',
                isSelected: _tempStatusCode.toUpperCase() == 'RETURNED',
                onSelected: (_) =>
                    setState(() => _tempStatusCode = 'RETURNED'),
                isDark: isDark,
              ),
              _buildFilterChoiceChip(
                label: 'Dibatalkan',
                isSelected: _tempStatusCode.toUpperCase() == 'CANCELLED',
                onSelected: (_) =>
                    setState(() => _tempStatusCode = 'CANCELLED'),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Tombol Terapkan
          CustomButton(
            text: 'Terapkan Filter',
            onPressed: () {
              widget.onApply(
                taskType: _tempTaskType,
                statusCode: _tempStatusCode,
                startDate: _tempStartDate,
                endDate: _tempEndDate,
                presetLabel: _tempPresetLabel,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required bool isDark,
    IconData? icon,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
    );
  }
}
