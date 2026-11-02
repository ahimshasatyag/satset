import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_shipment_detail.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class ShipmentDetailDialog extends StatelessWidget {
  final AdminShipmentDetail detail;
  final VoidCallback onClose;

  const ShipmentDetailDialog({
    super.key,
    required this.detail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AdminStatusHelper.getStatusColor(detail.statusKode, isDark: isDark);
    final statusBg = AdminStatusHelper.getStatusBgColor(detail.statusKode, isDark: isDark);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              detail.nomorResi,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                detail.statusNama,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Layanan ${detail.serviceNama} (${detail.serviceKode}) • Dibuat ${AdminDateFormatter.formatDateTime(detail.createdAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup Dialog',
                  ),
                ],
              ),
            ),

            // Content Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid Info Pengirim & Penerima
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pengirim
                        Expanded(
                          child: _InfoSection(
                            title: 'Informasi Pengirim',
                            icon: Icons.person_pin_circle_rounded,
                            color: AppColors.primary,
                            children: [
                              _InfoRow(label: 'Nama', value: detail.pengirimNama),
                              _InfoRow(label: 'No. HP', value: detail.pengirimNoHp),
                              _InfoRow(label: 'Alamat', value: detail.pengirimAlamat),
                              _InfoRow(
                                label: 'Kota / Pos',
                                value: '${detail.pengirimKota} ${detail.pengirimKodePos ?? ""}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Penerima
                        Expanded(
                          child: _InfoSection(
                            title: 'Informasi Penerima',
                            icon: Icons.location_on_rounded,
                            color: AppColors.secondary,
                            children: [
                              _InfoRow(label: 'Nama', value: detail.penerimaNama),
                              _InfoRow(label: 'No. HP', value: detail.penerimaNoHp),
                              _InfoRow(label: 'Alamat', value: detail.penerimaAlamat),
                              _InfoRow(
                                label: 'Kota / Pos',
                                value: '${detail.penerimaKota} ${detail.penerimaKodePos ?? ""}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid Paket & Pembayaran & Kurir
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Paket
                        Expanded(
                          child: _InfoSection(
                            title: 'Spesifikasi Paket',
                            icon: Icons.all_inbox_rounded,
                            color: AppColors.info,
                            children: [
                              _InfoRow(label: 'Berat Total', value: '${(detail.totalBeratGram / 1000).toStringAsFixed(2)} kg'),
                              _InfoRow(label: 'Dimensi (PxLxT)', value: '${detail.panjangCm} x ${detail.lebarCm} x ${detail.tinggiCm} cm'),
                              _InfoRow(label: 'Jumlah Barang', value: '${detail.totalBarang} barang'),
                              if (detail.catatanPengiriman != null && detail.catatanPengiriman!.isNotEmpty)
                                _InfoRow(label: 'Catatan', value: detail.catatanPengiriman!),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Pembayaran & Kurir
                        Expanded(
                          child: _InfoSection(
                            title: 'Biaya & Penugasan Kurir',
                            icon: Icons.payment_rounded,
                            color: AppColors.success,
                            children: [
                              _InfoRow(
                                label: 'Ongkos Kirim',
                                value: AdminCurrencyFormatter.formatRupiah(detail.biayaPengiriman),
                              ),
                              _InfoRow(
                                label: 'Total Biaya',
                                value: AdminCurrencyFormatter.formatRupiah(detail.totalBiaya),
                                isHighlight: true,
                              ),
                              _InfoRow(
                                label: 'Metode / Status',
                                value: '${detail.metodePembayaran} • ${AdminStatusHelper.getPaymentStatusLabel(detail.statusPembayaran)}',
                              ),
                              _InfoRow(
                                label: 'Kurir Pengantar',
                                value: detail.courierNama ?? 'Belum Ditugaskan',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Kronologi Jejak Pelacakan (t_shipment_tracking)
                    Text(
                      'Kronologi Jejak Pelacakan (t_shipment_tracking)',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Riwayat checkpoint operasional dari gudang hingga ke penerima',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (detail.trackingHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Belum ada catatan checkpoint riwayat pelacakan.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detail.trackingHistory.length,
                        itemBuilder: (context, idx) {
                          final track = detail.trackingHistory[idx];
                          final isFirst = idx == 0;
                          final trackColor = AdminStatusHelper.getStatusColor(track.statusKode, isDark: isDark);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline Bullet & Line
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isFirst ? trackColor : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: trackColor, width: 2),
                                    ),
                                  ),
                                  if (idx != detail.trackingHistory.length - 1)
                                    Container(
                                      width: 2,
                                      height: 45,
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Info Checkpoint
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            track.statusNama,
                                            style: AppTextStyles.labelMedium.copyWith(
                                              fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
                                              color: isFirst
                                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                            ),
                                          ),
                                          Text(
                                            AdminDateFormatter.formatDateTime(track.createdAt),
                                            style: AppTextStyles.labelSmall.copyWith(
                                              fontSize: 10,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        track.catatan,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Lokasi: ${track.lokasiNama}${track.employeeNama != null ? " • Petugas: ${track.employeeNama}" : ""}',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Footer Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

