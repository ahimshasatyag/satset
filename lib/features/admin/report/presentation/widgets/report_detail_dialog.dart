import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_detail.dart';

class ReportDetailDialog extends StatelessWidget {
  final AdminReportDetail detail;
  final VoidCallback onClose;

  const ReportDetailDialog({
    super.key,
    required this.detail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail.subtitle,
                          style: AppTextStyles.bodySmall,
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
            const Divider(height: 1),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (detail.shipmentRow != null)
                      _buildShipmentSummarySection(context),
                    if (detail.paymentRow != null)
                      _buildPaymentSummarySection(context),
                    if (detail.courierRow != null)
                      _buildCourierSummarySection(context),
                    if (detail.customerRow != null)
                      _buildCustomerSummarySection(context),
                    if (detail.relatedShipments.isNotEmpty)
                      _buildRelatedShipmentsSection(context),
                    if (detail.trackingHistory.isNotEmpty)
                      _buildTrackingSection(context),
                    if (detail.deliveryProofs.isNotEmpty)
                      _buildProofsSection(context),
                    if (detail.locationLogs.isNotEmpty)
                      _buildLocationsSection(context),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: onClose,
                    child: const Text('Tutup Detail Laporan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentSummarySection(BuildContext context) {
    final s = detail.shipmentRow!;
    return _SectionBox(
      title: 'Informasi Utama Pengiriman (t_shipments)',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _InfoField(label: 'Nomor Resi', value: s.nomorResi),
          _InfoField(
            label: 'Tanggal Transaksi',
            value: AdminDateFormatter.formatDateTime(s.createdAt),
          ),
          _InfoField(label: 'Pelanggan Pemesan', value: s.customerNama),
          _InfoField(
            label: 'Jenis Layanan',
            value: '${s.serviceKode} - ${s.serviceNama}',
          ),
          _InfoField(
            label: 'Status Pengiriman',
            value: '${s.statusNama} (${s.statusKode})',
          ),
          _InfoField(
            label: 'Kurir Ditugaskan',
            value: s.courierNama != null
                ? '${s.courierNama} (${s.courierCode ?? '-'})'
                : 'Belum Ditugaskan',
          ),
          _InfoField(
            label: 'Pengirim & Asal',
            value: '${s.pengirimNama} (${s.pengirimKota})',
          ),
          _InfoField(
            label: 'Penerima & Tujuan',
            value: '${s.penerimaNama} (${s.penerimaKota})',
          ),
          _InfoField(
            label: 'Berat Paket',
            value: '${s.totalBeratGram.toStringAsFixed(0)} gram',
          ),
          _InfoField(
            label: 'Total Biaya Pengiriman',
            value: AdminCurrencyFormatter.formatRupiah(s.totalBiaya),
          ),
          _InfoField(
            label: 'Metode & Status Bayar',
            value: '${s.metodePembayaran} • ${s.statusPembayaran}',
          ),
          if (s.deliveredAt != null)
            _InfoField(
              label: 'Waktu Diterima',
              value: AdminDateFormatter.formatDateTime(s.deliveredAt),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection(BuildContext context) {
    final p = detail.paymentRow!;
    return _SectionBox(
      title: 'Informasi Transaksi Pembayaran (t_shipment_payments)',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _InfoField(label: 'Nomor Pembayaran', value: p.nomorPembayaran),
          _InfoField(label: 'Nomor Resi', value: p.nomorResi),
          _InfoField(
            label: 'Tanggal Transaksi',
            value: AdminDateFormatter.formatDateTime(p.createdAt),
          ),
          _InfoField(label: 'Pelanggan', value: p.customerNama),
          _InfoField(
            label: 'Jenis Layanan',
            value: '${p.serviceKode} - ${p.serviceNama}',
          ),
          _InfoField(
            label: 'Status Pengiriman',
            value: '${p.shipmentStatusNama} (${p.shipmentStatusKode})',
          ),
          _InfoField(
            label: 'Kurir Bertugas',
            value: p.courierNama ?? 'Belum Ditugaskan',
          ),
          _InfoField(label: 'Metode Pembayaran', value: p.metodePembayaran),
          _InfoField(label: 'Status Pembayaran', value: p.statusPembayaran),
          _InfoField(
            label: 'Referensi Gateway',
            value: p.providerReference ?? p.provider ?? '-',
          ),
          _InfoField(
            label: 'Nominal Pembayaran',
            value: AdminCurrencyFormatter.formatRupiah(p.jumlahBayar),
          ),
          _InfoField(
            label: 'Waktu Lunas',
            value: p.paidAt != null
                ? AdminDateFormatter.formatDateTime(p.paidAt)
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildCourierSummarySection(BuildContext context) {
    final c = detail.courierRow!;
    return _SectionBox(
      title: 'Ringkasan Performa Kurir (m_employee & t_shipment_assignments)',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _InfoField(label: 'Nama Lengkap', value: c.namaLengkap),
          _InfoField(label: 'Kode Employee', value: c.employeeCode),
          _InfoField(label: 'Email', value: c.email),
          _InfoField(label: 'Nomor Telepon', value: c.noHp),
          _InfoField(
            label: 'Status Akun',
            value: c.isActive ? 'Aktif' : 'Nonaktif',
          ),
          _InfoField(
            label: 'Total Tugas Diterima',
            value: '${c.totalAssigned} Paket',
          ),
          _InfoField(
            label: 'Pengiriman Berhasil',
            value: '${c.deliveredCount} Paket',
          ),
          _InfoField(
            label: 'Tugas Sedang Berjalan',
            value: '${c.inProgressCount} Paket',
          ),
          _InfoField(
            label: 'Gagal / Dikembalikan',
            value: '${c.failedOrReturnedCount} Paket',
          ),
          _InfoField(
            label: 'Tingkat Keberhasilan',
            value: '${c.completionRate.toStringAsFixed(1)}%',
          ),
          _InfoField(
            label: 'Total COD Dikelola',
            value: AdminCurrencyFormatter.formatRupiah(c.totalCodHandled),
          ),
          _InfoField(
            label: 'Bukti Kirim & Log GPS',
            value:
                '${c.proofUploadedCount} Bukti • ${c.gpsLocationsCount} Titik GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSummarySection(BuildContext context) {
    final c = detail.customerRow!;
    return _SectionBox(
      title: 'Ringkasan Aktivitas Pelanggan (m_users & t_shipments)',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _InfoField(label: 'Nama Pelanggan', value: c.namaLengkap),
          _InfoField(label: 'Email', value: c.email),
          _InfoField(label: 'Nomor Telepon', value: c.noHp),
          _InfoField(
            label: 'Status Verifikasi Email',
            value: c.emailVerified ? 'Terverifikasi' : 'Belum Verifikasi',
          ),
          _InfoField(
            label: 'Total Pengiriman',
            value: '${c.totalShipments} Paket',
          ),
          _InfoField(
            label: 'Pengiriman Selesai',
            value: '${c.deliveredShipments} Paket',
          ),
          _InfoField(
            label: 'Pengiriman Berjalan',
            value: '${c.activeShipments} Paket',
          ),
          _InfoField(
            label: 'Gagal / Dibatalkan',
            value: '${c.failedOrCancelledShipments} Paket',
          ),
          _InfoField(
            label: 'Metode Pembayaran Dominan',
            value: c.preferredPaymentMethod,
          ),
          _InfoField(
            label: 'Total Nilai Transaksi',
            value: AdminCurrencyFormatter.formatRupiah(c.totalShippingSpend),
          ),
          _InfoField(
            label: 'Total Transaksi Lunas',
            value: AdminCurrencyFormatter.formatRupiah(c.paidShippingSpend),
          ),
          _InfoField(
            label: 'Pengiriman Terakhir',
            value: c.lastShipmentAt != null
                ? AdminDateFormatter.formatDateTime(c.lastShipmentAt)
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedShipmentsSection(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionBox(
      title:
          'Daftar Pengiriman Terkait (${detail.relatedShipments.length} Transaksi)',
      child: Column(
        children: detail.relatedShipments.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.nomorResi} • ${s.serviceKode} (${s.serviceNama})',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${s.pengirimNama} (${s.pengirimKota}) -> ${s.penerimaNama} (${s.penerimaKota})',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Tanggal: ${AdminDateFormatter.formatDateTime(s.createdAt)} • Kurir: ${s.courierNama ?? 'Belum Ditugaskan'}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AdminCurrencyFormatter.formatRupiah(s.totalBiaya),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${s.statusNama} • ${s.metodePembayaran} (${s.statusPembayaran})',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrackingSection(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionBox(
      title:
          'Riwayat Perjalanan & Perubahan Status Paket (t_shipment_tracking)',
      child: Column(
        children: detail.trackingHistory.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timeline_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.statusNama} (${t.statusKode})',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (t.lokasiNama != null && t.lokasiNama!.isNotEmpty)
                        Text(
                          'Lokasi: ${t.lokasiNama}',
                          style: AppTextStyles.bodySmall,
                        ),
                      if (t.catatan != null && t.catatan!.isNotEmpty)
                        Text(
                          'Catatan: ${t.catatan}',
                          style: AppTextStyles.bodySmall,
                        ),
                      Text(
                        'Waktu: ${AdminDateFormatter.formatDateTime(t.createdAt)}${t.employeeNama != null ? ' • Petugas: ${t.employeeNama}' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProofsSection(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionBox(
      title: 'Referensi Bukti Pengiriman (t_shipment_proofs)',
      child: Column(
        children: detail.deliveryProofs.map((pf) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jenis Bukti: ${pf.jenisBukti} • Penerima: ${pf.penerimaNama ?? '-'}',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pf.filePath != null && pf.filePath!.isNotEmpty)
                        Text(
                          'Path File: ${pf.filePath}',
                          style: AppTextStyles.bodySmall,
                        ),
                      if (pf.catatan != null && pf.catatan!.isNotEmpty)
                        Text(
                          'Catatan: ${pf.catatan}',
                          style: AppTextStyles.bodySmall,
                        ),
                      Text(
                        'Waktu Unggah: ${AdminDateFormatter.formatDateTime(pf.createdAt)}',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationsSection(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionBox(
      title: 'Rekaman Lokasi GPS Kurir Terakhir (t_shipment_locations)',
      child: Column(
        children: detail.locationLogs.map((loc) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Koordinat: (${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}) • Waktu: ${AdminDateFormatter.formatDateTime(loc.recordedAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBox({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
