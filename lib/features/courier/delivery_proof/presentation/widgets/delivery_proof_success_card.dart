import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/delivery_proof_item.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/entities/recipient_relationship.dart';

/// Kartu ringkasan bukti penyerahan yang berhasil dikonfirmasi
class DeliveryProofSuccessCard extends StatelessWidget {
  final DeliveryProofTask task;
  final DeliveryProofItem proof;
  final Uint8List? imageBytes;
  final VoidCallback onBackToTasks;
  final VoidCallback onResetForNextTask;

  const DeliveryProofSuccessCard({
    super.key,
    required this.task,
    required this.proof,
    this.imageBytes,
    required this.onBackToTasks,
    required this.onResetForNextTask,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute WIB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Icon Sukses
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Penyerahan Paket Berhasil!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Status paket telah diperbarui menjadi DELIVERED dan bukti penyerahan telah dicatat ke sistem.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Kartu Rincian Penyerahan
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Resi & Status DELIVERED
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.trackingNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const StatusBadge(
                      status: BadgeStatus.success,
                      label: 'DELIVERED',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Foto Bukti Terlampir jika ada
                if (imageBytes != null && imageBytes!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Baris Info Penerima
                _buildSummaryRow(
                  label: 'Penerima Aktual',
                  value: proof.recipientName,
                  isDark: isDark,
                  isBold: true,
                ),
                const SizedBox(height: 8),

                // Baris Relasi Penerima
                _buildSummaryRow(
                  label: 'Hubungan Penerima',
                  value: proof.relationship.label,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                // Baris Waktu Penyerahan
                _buildSummaryRow(
                  label: 'Waktu Penyerahan',
                  value: _formatDateTime(proof.createdAt),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                // Baris Alamat Tujuan
                _buildSummaryRow(
                  label: 'Alamat Tujuan',
                  value: task.fullDestinationAddress,
                  isDark: isDark,
                ),

                // Koordinat Lokasi jika ada
                if (proof.hasLocationCoordinates) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    label: 'Koordinat GPS',
                    value:
                        '${proof.latitude!.toStringAsFixed(5)}, ${proof.longitude!.toStringAsFixed(5)}',
                    isDark: isDark,
                  ),
                ],

                // Catatan tambahan jika ada
                if (proof.notes != null && proof.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    label: 'Keterangan',
                    value: proof.notes!,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Tombol Tindakan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Daftar Tugas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onBackToTasks,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Selesaikan Tugas Lainnya'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onResetForNextTask,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
