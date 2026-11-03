import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_detail.dart';
import '../../domain/entities/admin_payment_item.dart';

class PaymentDetailDialog extends StatelessWidget {
  final AdminPaymentDetail detail;
  final bool isActionInProgress;
  final VoidCallback onClose;
  final ValueChanged<AdminPaymentItem> onReconcilePayment;
  final ValueChanged<AdminPaymentItem> onConfirmCodPayment;
  final VoidCallback onOpenShipmentPage;

  const PaymentDetailDialog({
    super.key,
    required this.detail,
    this.isActionInProgress = false,
    required this.onClose,
    required this.onReconcilePayment,
    required this.onConfirmCodPayment,
    required this.onOpenShipmentPage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = detail.payment;
    final normStatus = p.normalizedStatus;
    final displayStatusCode = p.isCod && !p.isPaid ? 'COD' : normStatus;
    final statusColor = AdminStatusHelper.getPaymentStatusColor(
      displayStatusCode,
      isDark: isDark,
    );
    final statusLabel = p.isCod
        ? (p.isPaid ? 'COD Lunas (PAID)' : 'COD Belum Diselesaikan')
        : AdminStatusHelper.getPaymentStatusLabel(normStatus);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Transaksi Pembayaran
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
                      Icons.account_balance_wallet_rounded,
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
                              p.nomorPembayaran,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
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
                                statusLabel,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (p.isCod
                                        ? AppColors.secondary
                                        : AppColors.primary)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Metode: ${p.metodePembayaran}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: p.isCod
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Transaksi #${p.id} • Resi Pengiriman: ${p.nomorResi} • Dibuat: ${AdminDateFormatter.formatDateTime(p.createdAt)}',
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

            // 2. Isi Detail
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Baris 1: Identitas Customer & Informasi Pengiriman + Rincian Biaya & Validasi Nominal
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildCustomerAndShipmentCard(
                                  context,
                                  p,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCostBreakdownCard(
                                  context,
                                  p,
                                  isDark,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildCustomerAndShipmentCard(context, p, isDark),
                              const SizedBox(height: 16),
                              _buildCostBreakdownCard(context, p, isDark),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Baris 2: Informasi Spesifik Payment Gateway / Rekening Bank (m_jenis_bank & m_bank) ATAU COD
                    if (p.isCod)
                      _buildCodSection(context, p, isDark)
                    else
                      _buildGatewayAndBankSection(context, p, isDark),

                    const SizedBox(height: 18),

                    // Baris 3: Daftar Master Rekening Resmi SatSet (m_bank & m_jenis_bank)
                    if (detail.availableBanks.isNotEmpty) ...[
                      _buildRegisteredBankAccountsSection(isDark),
                      const SizedBox(height: 18),
                    ],

                    // Baris 4: Riwayat Perubahan Status & Audit Rekonsiliasi
                    _buildAuditLogsSection(isDark),
                  ],
                ),
              ),
            ),

            // 3. Footer Tombol Tindakan Tervalidasi Backend
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
                    onPressed: onOpenShipmentPage,
                    icon: const Icon(Icons.local_shipping_outlined, size: 17),
                    label: const Text('Buka di Delivery Management'),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isActionInProgress
                            ? null
                            : () => onReconcilePayment(p),
                        icon: const Icon(Icons.sync_lock_rounded, size: 17),
                        label: const Text('Rekonsiliasi & Validasi Backend'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: const BorderSide(color: AppColors.info),
                        ),
                      ),
                      if (p.isCod && !p.isPaid)
                        FilledButton.icon(
                          onPressed: isActionInProgress
                              ? null
                              : () => onConfirmCodPayment(p),
                          icon: const Icon(Icons.task_alt_rounded, size: 17),
                          label: const Text('Verifikasi Setoran COD Lunas'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      FilledButton(
                        onPressed: onClose,
                        child: const Text('Tutup Panel'),
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

  Widget _buildCustomerAndShipmentCard(
    BuildContext context,
    AdminPaymentItem p,
    bool isDark,
  ) {
    final shipmentColor = AdminStatusHelper.getStatusColor(
      p.shipmentStatusKode,
      isDark: isDark,
    );

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
                Icons.person_pin_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Identitas Customer & Pengiriman Terkait',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _infoRow('Nama Customer (m_users)', p.customerNama, isDark),
          _infoRow('Email Customer', p.customerEmail, isDark),
          _infoRow('Nomor Telepon', p.customerNoHp, isDark),
          _infoRow('Nomor Resi (t_shipments)', p.nomorResi, isDark, isMono: true),
          _infoRow('Barcode Paket', p.barcodeValue, isDark, isMono: true),
          _infoRow(
            'Jenis Layanan (m_service_types)',
            '${p.serviceNama} (${p.serviceKode})',
            isDark,
          ),
          _infoRow(
            'Rute Pengiriman',
            '${p.pengirimKota} → ${p.penerimaKota}',
            isDark,
          ),
          _infoRow(
            'Penerima Paket',
            '${p.penerimaNama} (${p.penerimaNoHp})',
            isDark,
          ),
          _infoRow(
            'Spesifikasi Paket',
            '${detail.totalBeratGram} gram • ${detail.totalBarang} koli',
            isDark,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pengiriman',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: shipmentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.shipmentStatusNama,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: shipmentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCard(
    BuildContext context,
    AdminPaymentItem p,
    bool isDark,
  ) {
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
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Rincian Biaya & Validasi Nominal',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _infoRow(
            'Biaya Pengiriman Pokok',
            AdminCurrencyFormatter.formatRupiah(p.biayaPengiriman),
            isDark,
          ),
          _infoRow(
            'Biaya Asuransi Pengiriman',
            AdminCurrencyFormatter.formatRupiah(p.biayaAsuransi),
            isDark,
          ),
          _infoRow(
            'Biaya Layanan Tambahan',
            AdminCurrencyFormatter.formatRupiah(p.biayaLayananTambahan),
            isDark,
          ),
          _infoRow(
            'Potongan Diskon',
            '- ${AdminCurrencyFormatter.formatRupiah(p.diskon)}',
            isDark,
          ),
          const Divider(height: 18),
          _infoRow(
            'Total Tagihan (t_shipments.total_biaya)',
            AdminCurrencyFormatter.formatRupiah(p.totalBiayaShipment),
            isDark,
            isBold: true,
          ),
          _infoRow(
            'Nominal Transaksi (t_shipment_payments)',
            AdminCurrencyFormatter.formatRupiah(p.jumlahBayar),
            isDark,
            isBold: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (p.isAmountMatched ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    (p.isAmountMatched ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  p.isAmountMatched
                      ? Icons.verified_user_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color:
                      p.isAmountMatched ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.isAmountMatched
                        ? 'Validasi Nominal Sesuai: jumlah_bayar pada t_shipment_payments cocok 100% dengan total_biaya pada t_shipments.'
                        : 'Selisih Nominal Terdeteksi: Gunakan tombol Rekonsiliasi & Validasi Backend untuk menyinkronkan jumlah_bayar dengan total_biaya.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: p.isAmountMatched
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
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

  Widget _buildGatewayAndBankSection(
    BuildContext context,
    AdminPaymentItem p,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informasi Payment Gateway, Instruksi Transfer & Rekening Bank (m_jenis_bank & m_bank)',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _badgeDetailBox(
                label: 'Provider / Channel Gateway',
                value: p.provider ?? p.namaJenisBank ?? 'TRANSFER_GATEWAY',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Jenis Bank (m_jenis_bank)',
                value: p.namaJenisBank ?? p.provider ?? '-',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Kode / Referensi Pembayaran Gateway',
                value: p.providerReference ?? '-',
                isDark: isDark,
                copyable: true,
                context: context,
              ),
              if (p.nomorRekeningBank != null &&
                  p.nomorRekeningBank!.isNotEmpty)
                _badgeDetailBox(
                  label: 'Rekening Tujuan (m_bank)',
                  value:
                      '${p.nomorRekeningBank} (a.n. ${p.namaPemilikRekening ?? "SatSet"})',
                  isDark: isDark,
                ),
              _badgeDetailBox(
                label: 'Batas Waktu Pembayaran (expired_at)',
                value: p.expiredAt != null
                    ? AdminDateFormatter.formatDateTime(p.expiredAt)
                    : '-',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Waktu Pelunasan (paid_at)',
                value: p.paidAt != null
                    ? AdminDateFormatter.formatDateTime(p.paidAt)
                    : 'Belum Dibayar',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.info,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keamanan & Idempotensi Webhook: Konfirmasi pelunasan pembayaran transfer berasal dari webhook payment gateway yang diverifikasi secara kriptografis dan idempoten oleh backend (bukan dari klaim manual frontend). Admin dapat menjalankan Rekonsiliasi & Validasi Backend untuk memeriksa kesesuaian nominal atau status kedaluwarsa.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
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

  Widget _buildCodSection(
    BuildContext context,
    AdminPaymentItem p,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_rounded,
                size: 19,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informasi Penagihan & Penyelesaian Cash on Delivery (COD)',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _badgeDetailBox(
                label: 'Nominal Tagihan COD ke Penerima',
                value: AdminCurrencyFormatter.formatRupiah(p.jumlahBayar),
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Status Penyelesaian COD',
                value: p.isPaid
                    ? 'Sudah Disetor & Lunas (PAID)'
                    : 'Belum Diselesaikan (Menunggu Setoran)',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Kurir Penanggung Jawab',
                value: detail.courierNama != null
                    ? '${detail.courierNama} (${detail.courierNoHp ?? "-"})'
                    : 'Belum Ada Kurir Ditugaskan',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Referensi Setoran COD',
                value: p.providerReference ?? '-',
                isDark: isDark,
              ),
              _badgeDetailBox(
                label: 'Waktu Penyelesaian COD (paid_at)',
                value: p.paidAt != null
                    ? AdminDateFormatter.formatDateTime(p.paidAt)
                    : 'Belum Disetor',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredBankAccountsSection(bool isDark) {
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
              const Icon(
                Icons.assured_workload_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Referensi Rekening Bank Resmi SatSet (m_bank & m_jenis_bank)',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: detail.availableBanks.map((b) {
              final isUsed = detail.payment.jenisBankId == b.jenisBankId ||
                  (detail.payment.namaJenisBank ?? '').toUpperCase() ==
                      b.namaJenisBank.toUpperCase();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isUsed
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark ? AppColors.surfaceDark : AppColors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUsed
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank ${b.namaJenisBank}',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUsed ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      '${b.nomorRekening} • a.n. ${b.namaPemilik}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsSection(bool isDark) {
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
                Icons.history_edu_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Riwayat Perubahan Status & Audit Transaksi (t_shipment_tracking & t_notifications)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          if (detail.auditLogs.isEmpty)
            Text(
              'Belum ada riwayat perubahan status atau catatan audit pada transaksi ini.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...detail.auditLogs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.title,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                AdminDateFormatter.formatDateTime(
                                  log.createdAt,
                                ),
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Sumber Audit: ${log.source}',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
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
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 195,
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
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
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

  Widget _badgeDetailBox({
    required String label,
    required String value,
    required bool isDark,
    bool copyable = false,
    BuildContext? context,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (copyable && context != null && value != '-') ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode referensi disalin ke clipboard.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
