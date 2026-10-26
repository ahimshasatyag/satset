import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/utils/currency_formatter.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/courier_task_history_detail.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/entities/shipment_proof_history_item.dart';
import '../../domain/entities/shipment_tracking_history_item.dart';

/// Bottom sheet detail riwayat tugas kurir lengkap dengan kronologi tracking & bukti pengiriman
class CourierTaskHistoryDetailSheet extends StatelessWidget {
  final CourierTaskHistoryDetail detail;

  const CourierTaskHistoryDetailSheet({
    super.key,
    required this.detail,
  });

  static Future<void> show(
    BuildContext context, {
    required CourierTaskHistoryDetail detail,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourierTaskHistoryDetailSheet(detail: detail),
    );
  }

  BadgeStatus _resolveBadgeStatus(String code) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return BadgeStatus.success;
      case 'FAILED_DELIVERY':
      case 'CANCELLED':
      case 'RETURNED':
        return BadgeStatus.error;
      case 'OUT_FOR_DELIVERY':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        return BadgeStatus.brand;
      default:
        return BadgeStatus.warning;
    }
  }

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
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final task = detail.task;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header Resi & Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskTypeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: task.isPickup ? AppColors.secondary : AppColors.tertiary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          task.trackingNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: task.trackingNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nomor resi ${task.trackingNumber} disalin!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(
                  label: task.statusName,
                  status: _resolveBadgeStatus(task.statusCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Content Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Alasan Kegagalan / Pengembalian jika ada
                if (task.hasFailureReason) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: isDark ? 0.2 : 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan Kendala / Alasan:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.failureOrReturnReason!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Kartu Rincian Alamat & Pihak
                _buildSectionHeader(
                  title: 'Informasi Serah Terima',
                  icon: Icons.swap_horiz_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildAddressCard(task: task, isDark: isDark),
                const SizedBox(height: 20),

                // 3. Rincian Paket & Layanan
                _buildSectionHeader(
                  title: 'Detail Pengiriman',
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPackageDetails(task: task, isDark: isDark),
                const SizedBox(height: 20),

                // 4. Waktu & Riwayat Penugasan
                _buildSectionHeader(
                  title: 'Waktu Aktivitas Penugasan',
                  icon: Icons.timeline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildTimeDetails(task: task, isDark: isDark),
                const SizedBox(height: 24),

                // 5. Kronologi Jejak Perubahan Status (t_shipment_tracking)
                _buildSectionHeader(
                  title: 'Kronologi Jejak Pelacakan',
                  icon: Icons.route_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildTrackingTimeline(
                  timeline: detail.trackingTimeline,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 6. Bukti Pengiriman (t_shipment_proofs)
                _buildSectionHeader(
                  title: 'Bukti Serah Terima / Pengiriman',
                  icon: Icons.verified_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildProofsSection(
                  proofs: detail.proofs,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard({
    required CourierTaskHistoryItem task,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Pengirim
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengirim: ${task.senderName} (${task.senderPhone})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${task.senderAddress}, ${task.senderCity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          // Penerima
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 12, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penerima: ${task.receiverName} (${task.receiverPhone})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${task.receiverAddress}, ${task.receiverCity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetails({
    required CourierTaskHistoryItem task,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Jenis Layanan', task.serviceTypeName, isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Nama / Isi Barang', task.itemName, isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Berat Paket', task.weightFormatted, isDark),
          const SizedBox(height: 8),
          _buildInfoRow('Metode Pembayaran', task.paymentMethod, isDark),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Total Ongkir',
            CurrencyFormatter.formatRupiah(task.totalFee),
            isDark,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetails({
    required CourierTaskHistoryItem task,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Waktu Ditugaskan',
            _formatDateTime(task.assignedAt),
            isDark,
          ),
          if (task.acceptedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Waktu Diterima Kurir',
              _formatDateTime(task.acceptedAt!),
              isDark,
            ),
          ],
          if (task.pickedUpAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Waktu Paket Dijemput',
              _formatDateTime(task.pickedUpAt!),
              isDark,
            ),
          ],
          if (task.deliveredAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Waktu Paket Diserahkan',
              _formatDateTime(task.deliveredAt!),
              isDark,
            ),
          ],
          if (task.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Waktu Penugasan Selesai',
              _formatDateTime(task.completedAt!),
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline({
    required List<ShipmentTrackingHistoryItem> timeline,
    required bool isDark,
  }) {
    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Belum ada catatan jejak pelacakan di database.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textMutedLight,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final entry = timeline[index];
        final isFirst = index == 0;
        final isLast = index == timeline.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis Indikator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isFirst ? AppColors.primary : (isDark ? Colors.white30 : Colors.black26),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Detail Jejak
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.statusName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
                                color: isFirst
                                    ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                    : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                          Text(
                            _formatDateTime(entry.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      if (entry.locationName != null && entry.locationName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark ? Colors.white54 : AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.locationName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProofsSection({
    required List<ShipmentProofHistoryItem> proofs,
    required bool isDark,
  }) {
    if (proofs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Tidak ada berkas bukti fisik serah terima untuk pengiriman ini.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textMutedLight,
            ),
          ),
        ),
      );
    }

    return Column(
      children: proofs.map((proof) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        proof.isSignature ? Icons.draw_rounded : Icons.photo_camera_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        proof.proofTypeLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDateTime(proof.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Gambar atau Foto Bukti jika valid URL
              if (proof.filePath.startsWith('http')) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    proof.filePath,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildProofPlaceholder(proof, isDark),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                _buildProofPlaceholder(proof, isDark),
                const SizedBox(height: 8),
              ],

              if (proof.recipientName != null && proof.recipientName!.isNotEmpty) ...[
                Text(
                  'Diterima oleh: ${proof.recipientName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              if (proof.notes != null && proof.notes!.isNotEmpty) ...[
                Text(
                  'Catatan: ${proof.notes}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                  ),
                ),
              ],

              if (proof.latitude != null && proof.longitude != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      size: 12,
                      color: isDark ? Colors.white54 : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GPS: ${proof.latitude!.toStringAsFixed(5)}, ${proof.longitude!.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProofPlaceholder(ShipmentProofHistoryItem proof, bool isDark) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              proof.isSignature ? Icons.draw_rounded : Icons.photo_outlined,
              size: 28,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 4),
            Text(
              'Berkas Dokumen: ${proof.filePath.split('/').last}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : AppColors.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
