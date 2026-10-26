import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

class TaskStatusFailureDialog extends StatefulWidget {
  final Function(String reason, String notes) onConfirm;

  const TaskStatusFailureDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(String reason, String notes) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskStatusFailureDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<TaskStatusFailureDialog> createState() => _TaskStatusFailureDialogState();
}

class _TaskStatusFailureDialogState extends State<TaskStatusFailureDialog> {
  static const List<String> _failureReasons = [
    'Penerima Tidak di Tempat / Rumah Kosong',
    'Alamat Tidak Ditemukan atau Tidak Jelas',
    'Nomor Telepon Tidak Dapat Dihubungi',
    'Penerima Menolak Menerima Paket',
    'Akses Jalan Menuju Lokasi Ditutup / Terhalang',
    'Paket Rusak Saat Pengantaran',
    'Lainnya',
  ];

  String? _selectedReason;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Laporkan Pengantaran Gagal',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih alasan operasional mengapa paket ini tidak dapat diserahkan ke penerima.',
              style: AppTextStyles.bodySmall.copyWith(
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Opsi Alasan
            Text(
              'Alasan Utama *',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            ..._failureReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.error.withValues(alpha: 0.1)
                        : surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.error
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? AppColors.error : textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Catatan Tambahan
            CustomTextField(
              controller: _notesController,
              label: 'Catatan Tambahan (Opsional)',
              hintText: 'Misal: Sudah menunggu 15 menit, tetangga konfirmasi rumah kosong.',
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Tombol Konfirmasi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Kirim Laporan',
                    onPressed: _selectedReason == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onConfirm(
                              _selectedReason!,
                              _notesController.text.trim(),
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
