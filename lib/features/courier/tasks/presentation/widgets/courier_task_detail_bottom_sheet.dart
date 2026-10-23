import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/utils/currency_formatter.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/courier_task.dart';

class CourierTaskDetailBottomSheet extends StatelessWidget {
  final CourierTask task;
  final Function(String newStatusCode, String? notes)? onUpdateStatus;
  final VoidCallback? onOpenScanner;
  final VoidCallback? onOpenLocationTracking;
  final VoidCallback? onOpenDeliveryProof;
  final VoidCallback? onOpenTaskHistory;

  const CourierTaskDetailBottomSheet({
    super.key,
    required this.task,
    this.onUpdateStatus,
    this.onOpenScanner,
    this.onOpenLocationTracking,
    this.onOpenDeliveryProof,
    this.onOpenTaskHistory,
  });

  static Future<void> show(
    BuildContext context, {
    required CourierTask task,
    Function(String newStatusCode, String? notes)? onUpdateStatus,
    VoidCallback? onOpenScanner,
    VoidCallback? onOpenLocationTracking,
    VoidCallback? onOpenDeliveryProof,
    VoidCallback? onOpenTaskHistory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourierTaskDetailBottomSheet(
        task: task,
        onUpdateStatus: onUpdateStatus,
        onOpenScanner: onOpenScanner,
        onOpenLocationTracking: onOpenLocationTracking,
        onOpenDeliveryProof: onOpenDeliveryProof,
        onOpenTaskHistory: onOpenTaskHistory,
      ),
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
      case 'PICKUP_SCHEDULED':
      case 'CONFIRMED':
      case 'PENDING':
      default:
        return BadgeStatus.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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

          // Header
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
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: task.trackingNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor resi disalin ke papan klip'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // 1. Status Banner Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      StatusBadge(
                        label: task.statusName,
                        status: _resolveBadgeStatus(task.statusCode),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.statusDescription,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Hubungi Pihak Terkait (Tombol Telepon Cepat)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: task.targetPersonPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nomor ${task.targetPersonName} (${task.targetPersonPhone}) disalin!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: Text(
                          'Salin No. ${task.isPickup ? "Pengirim" : "Penerima"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Info Pengirim & Penjemputan
                _buildSectionHeader('Informasi Pengirim (Asal)', Icons.arrow_upward_rounded),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildDetailRow('Nama Pengirim', task.senderName),
                    _buildDetailRow('No. Telepon', task.senderPhone),
                    _buildDetailRow('Alamat Asal', '${task.senderAddress}, ${task.senderCity}'),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Info Penerima & Pengantaran
                _buildSectionHeader('Informasi Penerima (Tujuan)', Icons.arrow_downward_rounded),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildDetailRow('Nama Penerima', task.receiverName),
                    _buildDetailRow('No. Telepon', task.receiverPhone),
                    _buildDetailRow('Alamat Tujuan', '${task.receiverAddress}, ${task.receiverCity}'),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Rincian Paket & Layanan
                _buildSectionHeader('Detail Paket & Tagihan', Icons.inventory_2_outlined),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildDetailRow('Nama Barang', task.itemName),
                    _buildDetailRow('Jenis Layanan', '${task.serviceTypeName} (${task.serviceTypeCode})'),
                    _buildDetailRow('Berat Paket', task.weightFormatted),
                    _buildDetailRow('Metode Pembayaran', task.paymentMethod),
                    _buildDetailRow('Total Biaya', CurrencyFormatter.formatRupiah(task.totalFee)),
                    if (task.notes != null && task.notes!.isNotEmpty)
                      _buildDetailRow('Catatan Tambahan', task.notes!),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Navigasi Cepat Fitur Terkait Kurir
                _buildSectionHeader('Aksi & Halaman Terkait', Icons.dashboard_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureButton(
                      context,
                      label: 'Scan Barcode',
                      icon: Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenScanner?.call();
                      },
                    ),
                    _buildFeatureButton(
                      context,
                      label: 'Pelacakan Rute (GPS)',
                      icon: Icons.navigation_outlined,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenLocationTracking?.call();
                      },
                    ),
                    _buildFeatureButton(
                      context,
                      label: 'Bukti Serah Terima',
                      icon: Icons.camera_alt_outlined,
                      color: AppColors.tertiary,
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenDeliveryProof?.call();
                      },
                    ),
                    _buildFeatureButton(
                      context,
                      label: 'Riwayat Jejak',
                      icon: Icons.history_rounded,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenTaskHistory?.call();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Bar: Update Status Tugas
          if (task.validNextStatuses.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: task.validNextStatuses.map((nextCode) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          _showStatusConfirmationDialog(context, nextCode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nextCode == 'FAILED_DELIVERY'
                              ? AppColors.error
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _actionLabelForCode(nextCode),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showStatusConfirmationDialog(BuildContext context, String nextCode) {
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Pembaruan Status', style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perbarui status pesanan ${task.trackingNumber} menjadi:\n'
              '"${_actionLabelForCode(nextCode)}"?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Catatan Opsional',
                hintText: 'Contoh: Paket diterima oleh ybs / titip satpam',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Tutup bottom sheet
              onUpdateStatus?.call(nextCode, notesCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nextCode == 'FAILED_DELIVERY' ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  String _actionLabelForCode(String code) {
    switch (code) {
      case 'PICKED_UP':
        return 'Tandai Dijemput (Picked Up)';
      case 'IN_TRANSIT':
        return 'Bawa ke Fasilitas Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Mulai Pengantaran (Out for Delivery)';
      case 'DELIVERED':
        return 'Tandai Terkirim (Delivered)';
      case 'FAILED_DELIVERY':
        return 'Gagal Diantar';
      case 'RETURNED':
        return 'Kembalikan Paket';
      default:
        return 'Update $code';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
