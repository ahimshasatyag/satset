import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/admin_assignable_courier.dart';

class CourierAssignmentDialog extends StatefulWidget {
  final int shipmentId;
  final String nomorResi;
  final int? currentCourierId;
  final String? currentCourierName;
  final List<AdminAssignableCourier> couriers;
  final void Function(int courierId, String? notes) onConfirmAssignment;

  const CourierAssignmentDialog({
    super.key,
    required this.shipmentId,
    required this.nomorResi,
    this.currentCourierId,
    this.currentCourierName,
    required this.couriers,
    required this.onConfirmAssignment,
  });

  @override
  State<CourierAssignmentDialog> createState() =>
      _CourierAssignmentDialogState();
}

class _CourierAssignmentDialogState extends State<CourierAssignmentDialog> {
  int? _selectedCourierId;
  String _searchQuery = '';
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCourierId = widget.currentCourierId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter hanya kurir dari m_employee (id_users_role = 2) yang cocok dengan pencarian
    final eligibleCouriers = widget.couriers.where((c) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return c.namaLengkap.toLowerCase().contains(q) ||
          c.employeeCode.toLowerCase().contains(q) ||
          c.noHp.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentCourierId != null
                              ? 'Perbarui Penugasan Kurir'
                              : 'Tugaskan Kurir Pengiriman',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Resi: ${widget.nomorResi} • Pilih kurir aktif (id_users_role = 2)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (widget.currentCourierName != null &&
                  widget.currentCourierName != 'Belum Ditugaskan') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kurir saat ini: ${widget.currentCourierName}. Memilih kurir baru akan menonaktifkan penugasan sebelumnya secara otomatis.',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Pencarian Kurir
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari nama kurir, kode pegawai, atau no. HP...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Daftar Kurir
              Expanded(
                child: eligibleCouriers.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada data kurir (id_users_role = 2) yang ditemukan.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: eligibleCouriers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final courier = eligibleCouriers[index];
                          final isSelected = _selectedCourierId == courier.id;
                          final isEligible = courier.isEligibleForAssignment;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isEligible
                                  ? () => setState(
                                      () => _selectedCourierId = courier.id,
                                    )
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: isDark ? 0.2 : 0.08,
                                        )
                                      : (isDark
                                            ? AppColors.backgroundDark
                                            : AppColors.backgroundLight),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isEligible
                                          ? AppColors.primary
                                          : Colors.grey,
                                      child: Text(
                                        courier.namaLengkap.isNotEmpty
                                            ? courier.namaLengkap[0]
                                                  .toUpperCase()
                                            : 'K',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  courier.namaLengkap,
                                                  style: AppTextStyles
                                                      .labelLarge
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  courier.employeeCode,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${courier.noHp} • ${courier.email}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: !courier.isActive
                                                      ? AppColors.error
                                                      : (courier.activeAssignmentsCount ==
                                                                0
                                                            ? AppColors.success
                                                            : AppColors.info),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${courier.availabilityLabel} • Selesai: ${courier.completedAssignmentsCount}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: !courier.isActive
                                                      ? AppColors.error
                                                      : (courier.activeAssignmentsCount ==
                                                                0
                                                            ? AppColors.success
                                                            : AppColors.info),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: !isEligible
                                          ? Colors.grey
                                          : (isSelected
                                                ? AppColors.primary
                                                : Colors.grey),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Catatan Penugasan
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Penugasan (Opsional)',
                  hintText: 'Contoh: Segera jemput paket di alamat pengirim sebelum pukul 15:00 WIB...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed:
                        _selectedCourierId == null ||
                            _selectedCourierId == widget.currentCourierId
                        ? null
                        : () {
                            final selectedId = _selectedCourierId!;
                            final notes = _notesController.text.trim();
                            Navigator.of(context).pop();
                            widget.onConfirmAssignment(
                              selectedId,
                              notes.isEmpty ? null : notes,
                            );
                          },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Simpan Penugasan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
