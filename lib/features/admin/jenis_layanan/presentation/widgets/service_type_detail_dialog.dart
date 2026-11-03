import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_service_type_detail.dart';
import '../../domain/entities/admin_service_type_item.dart';

class ServiceTypeDetailDialog extends StatelessWidget {
  final AdminServiceTypeDetail detail;
  final bool isActionInProgress;
  final VoidCallback onClose;
  final ValueChanged<AdminServiceTypeItem> onEditService;
  final ValueChanged<AdminServiceTypeItem> onToggleStatus;
  final ValueChanged<AdminServiceTypeItem> onDeleteService;
  final VoidCallback onOpenDeliveryPage;

  const ServiceTypeDetailDialog({
    super.key,
    required this.detail,
    this.isActionInProgress = false,
    required this.onClose,
    required this.onEditService,
    required this.onToggleStatus,
    required this.onDeleteService,
    required this.onOpenDeliveryPage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = detail.serviceType;
    final statusColor = s.isActive ? AppColors.success : AppColors.warning;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Jenis Layanan
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              s.namaLayanan,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Kode: ${s.kode}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.isActive
                                    ? 'Aktif (Tersedia di Pesanan)'
                                    : 'Nonaktif (Arsip Histori)',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Layanan #${s.id} • Dibuat: ${AdminDateFormatter.formatDateTime(s.createdAt)}',
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
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // 2. Konten Detail
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildServiceInfoCard(s, isDark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTariffRuleAndUsageCard(s, isDark),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildServiceInfoCard(s, isDark),
                              const SizedBox(height: 16),
                              _buildTariffRuleAndUsageCard(s, isDark),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Daftar Riwayat Pengiriman yang Menggunakan Layanan Ini
                    _buildRecentShipmentsSection(isDark),
                  ],
                ),
              ),
            ),

            // 3. Footer Aksi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenDeliveryPage,
                    icon: const Icon(Icons.local_shipping_outlined, size: 17),
                    label: const Text('Buka Halaman Pengiriman'),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (s.canBeDeleted)
                        OutlinedButton.icon(
                          onPressed: isActionInProgress
                              ? null
                              : () => onDeleteService(s),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Hapus Layanan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: isActionInProgress
                            ? null
                            : () => onToggleStatus(s),
                        icon: Icon(
                          s.isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 17,
                        ),
                        label: Text(
                          s.isActive
                              ? 'Nonaktifkan Layanan'
                              : 'Aktifkan Layanan',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              s.isActive ? AppColors.warning : AppColors.success,
                          side: BorderSide(
                            color: s.isActive
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            isActionInProgress ? null : () => onEditService(s),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit Layanan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(AdminServiceTypeItem s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.settings_suggest_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Master Layanan (m_service_types)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _infoRow('ID Layanan (id)', '#${s.id}', isDark, isMono: true),
          _infoRow('Kode Layanan (kode)', s.kode, isDark, isMono: true),
          _infoRow('Nama Layanan (nama_layanan)', s.namaLayanan, isDark),
          _infoRow(
            'Estimasi Waktu (SLA)',
            s.formattedEstimasi,
            isDark,
          ),
          _infoRow(
            'Rentang Hari (Min - Maks)',
            '${s.estimasiHariMin} s/d ${s.estimasiHariMax} Hari',
            isDark,
          ),
          _infoRow(
            'Status Aktif (is_active)',
            s.isActive ? 'true (Aktif)' : 'false (Tidak Aktif)',
            isDark,
          ),
          _infoRow(
            'Deskripsi (deskripsi)',
            s.deskripsi != null && s.deskripsi!.trim().isNotEmpty
                ? s.deskripsi!
                : '-',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTariffRuleAndUsageCard(AdminServiceTypeItem s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.calculate_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Aturan Perhitungan Tarif & Relasi Pengiriman',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _infoRow(
            'Tarif Dasar per Kg',
            '${AdminCurrencyFormatter.formatRupiah(s.baseTariffPerKg)} / Kg',
            isDark,
          ),
          _infoRow(
            'Tarif Premi Asuransi',
            s.formattedInsuranceRate,
            isDark,
          ),
          _infoRow(
            'Rumus Berat Volumetrik',
            '(P × L × T cm) / 6000 = Kg Volumetrik',
            isDark,
          ),
          _infoRow(
            'Total Pengiriman (t_shipments)',
            '${s.totalShipmentsCount} Transaksi',
            isDark,
          ),
          _infoRow(
            'Pengiriman Aktif / Selesai',
            '${s.activeShipmentsCount} Aktif • ${s.deliveredShipmentsCount} Terkirim',
            isDark,
          ),
          _infoRow(
            'Akumulasi Nilai Transaksi',
            AdminCurrencyFormatter.formatRupiah(s.totalRevenueAmount),
            isDark,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (s.isUsedInShipments ? AppColors.info : AppColors.success)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    (s.isUsedInShipments ? AppColors.info : AppColors.success)
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  s.isUsedInShipments
                      ? Icons.lock_clock_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                  color:
                      s.isUsedInShipments ? AppColors.info : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.isUsedInShipments
                        ? 'Proteksi Relasi Historis: Layanan ini digunakan pada ${s.totalShipmentsCount} pengiriman. Penghapusan fisik dikunci agar histori t_shipments tetap utuh; gunakan Nonaktifkan bila layanan dihentikan.'
                        : 'Layanan ini belum memiliki relasi transaksi pada t_shipments sehingga dapat dihapus atau dinonaktifkan.',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: s.isUsedInShipments
                          ? AppColors.info
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShipmentsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Daftar Pengiriman Terbaru dengan Layanan Ini (t_shipments)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          if (detail.recentShipments.isEmpty)
            Text(
              'Belum ada transaksi pengiriman pada t_shipments yang menggunakan jenis layanan ini.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...detail.recentShipments.map((sh) {
              final stColor = AdminStatusHelper.getStatusColor(
                sh.statusKode,
                isDark: isDark,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sh.nomorResi,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${sh.pengirimNama} (${sh.pengirimKota}) → ${sh.penerimaNama} (${sh.penerimaKota})',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AdminCurrencyFormatter.formatRupiah(
                                sh.totalBiaya,
                              ),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${sh.totalBeratGram} gr • ${AdminDateFormatter.formatShortDate(sh.createdAt)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sh.statusNama,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: stColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    bool isDark, {
    bool isMono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: isMono ? 'monospace' : null,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

