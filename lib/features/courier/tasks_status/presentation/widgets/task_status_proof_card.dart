import 'package:flutter/material.dart';
import 'package:satset/features/courier/delivery_proof/presentation/pages/courier_delivery_proof_page.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/delivery_proof_summary.dart';

class TaskStatusProofCard extends StatelessWidget {
  final String shipmentId;
  final DeliveryProofSummary? proof;
  final bool isDelivered;
  final VoidCallback? onProofUpdated;

  const TaskStatusProofCard({
    super.key,
    required this.shipmentId,
    this.proof,
    required this.isDelivered,
    this.onProofUpdated,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const Text(
                      'Gagal memuat foto bukti',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bukti Penyerahan Paket',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (proof != null)
                const StatusBadge.success(
                  label: 'Terverifikasi',
                  showDot: false,
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (proof != null) ...[
            // Penerima Aktual
            Row(
              children: [
                Icon(
                  Icons.person_pin_rounded,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Diterima oleh: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
                Text(
                  proof!.recipientName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Waktu Penyerahan
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Waktu serah: ${_formatDateTime(proof!.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),

            if (proof!.notes != null && proof!.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${proof!.notes!}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Foto Bukti
            if (proof!.hasValidPhoto) ...[
              GestureDetector(
                onTap: () => _showImagePreviewDialog(context, proof!.filePath),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        proof!.filePath,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: surfaceVariant,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image_outlined, size: 36),
                                const SizedBox(height: 4),
                                Text(
                                  'Foto bukti tersimpan di database',
                                  style: AppTextStyles.labelSmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Lihat Foto',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            // Bukti belum tersedia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered
                              ? 'Bukti serah terima belum diunggah'
                              : 'Bukti serah terima belum tersedia',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDelivered
                              ? 'Paket telah ditandai diterima namun berkas bukti belum lengkap.'
                              : 'Foto penerima dan tanda tangan wajib dilengkapi saat pengantaran selesai.',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isDelivered) ...[
              const SizedBox(height: 12),
              CustomButton(
                text: 'Lengkapi Bukti Pengiriman',
                prefixIcon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                isFullWidth: true,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    SmoothPageRoute(
                      child: CourierDeliveryProofPage(
                        initialShipmentId: shipmentId,
                      ),
                    ),
                  );
                  onProofUpdated?.call();
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
