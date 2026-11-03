import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_assignable_courier.dart';
import '../../domain/entities/admin_delivery_detail.dart';
import 'admin_searchable_dropdown.dart';
import 'courier_assignment_dialog.dart';

class DeliveryDetailDialog extends StatefulWidget {
  final AdminDeliveryDetail detail;
  final List<AdminAssignableCourier> couriers;
  final List<Map<String, dynamic>> statusOptions;
  final bool isActionInProgress;
  final VoidCallback onClose;
  final void Function(String? notes) onConfirmOrder;
  final void Function(int courierId, String? notes) onAssignCourier;
  final void Function(String targetStatusCode, String? lokasiNama, String? notes)
      onUpdateStatus;
  final void Function(
    String resolutionAction,
    int? reassignCourierId,
    String? notes,
  ) onHandleFailed;

  const DeliveryDetailDialog({
    super.key,
    required this.detail,
    required this.couriers,
    required this.statusOptions,
    this.isActionInProgress = false,
    required this.onClose,
    required this.onConfirmOrder,
    required this.onAssignCourier,
    required this.onUpdateStatus,
    required this.onHandleFailed,
  });

  @override
  State<DeliveryDetailDialog> createState() => _DeliveryDetailDialogState();
}

class _DeliveryDetailDialogState extends State<DeliveryDetailDialog> {
  Future<void> _showUpdateStatusModal(BuildContext context) async {
    String selectedCode = widget.detail.statusKode;
    final lokasiController = TextEditingController(
      text: 'Pusat Operasional SatSet',
    );
    final catatanController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Perbarui Status Pengiriman'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminSearchableDropdown<String>(
                      value: selectedCode,
                      width: double.infinity,
                      labelText: 'Pilih Status Baru',
                      searchHintText: 'Cari status baru...',
                      options: widget.statusOptions.map((opt) {
                        final code = (opt['kode'] ?? '').toString().toUpperCase();
                        final name = (opt['nama_status'] ?? code).toString();
                        return AdminDropdownOption<String>(
                          value: code,
                          label: '$name ($code)',
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedCode = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lokasiController,
                      decoration: InputDecoration(
                        labelText: 'Lokasi Pembaruan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: catatanController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Kronologi Tracking',
                        hintText: 'Masukkan keterangan perubahan status...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      widget.onUpdateStatus(
        selectedCode,
        lokasiController.text.trim(),
        catatanController.text.trim().isEmpty
            ? null
            : catatanController.text.trim(),
      );
    }
  }

  Future<void> _showFailedResolutionModal(BuildContext context) async {
    String selectedAction = 'RESCHEDULE_DELIVERY';
    int? selectedCourierId = widget.detail.courierId;
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Penanganan Pengiriman Gagal'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminSearchableDropdown<String>(
                      value: selectedAction,
                      width: double.infinity,
                      labelText: 'Tindakan Resolusi',
                      searchHintText: 'Cari tindakan resolusi...',
                      options: const [
                        AdminDropdownOption(
                          value: 'RESCHEDULE_DELIVERY',
                          label: 'Jadwalkan Pengantaran Ulang',
                        ),
                        AdminDropdownOption(
                          value: 'REASSIGN_COURIER',
                          label: 'Tugaskan ke Kurir Pengganti',
                        ),
                        AdminDropdownOption(
                          value: 'RETURN_TO_SENDER',
                          label: 'Kembalikan ke Pengirim (Retur)',
                        ),
                        AdminDropdownOption(
                          value: 'CANCEL_SHIPMENT',
                          label: 'Batalkan Pengiriman',
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedAction = val);
                      },
                    ),
                    if (selectedAction == 'REASSIGN_COURIER') ...[
                      const SizedBox(height: 12),
                      AdminSearchableDropdown<int?>(
                        value: selectedCourierId,
                        width: double.infinity,
                        labelText: 'Pilih Kurir Pengganti (id_users_role = 2)',
                        hintText: 'Pilih kurir pengganti...',
                        searchHintText: 'Cari nama / kode kurir...',
                        options: widget.couriers
                            .where((c) => c.isEligibleForAssignment)
                            .map((c) {
                          return AdminDropdownOption<int?>(
                            value: c.id,
                            label:
                                '${c.namaLengkap} (${c.employeeCode}) • ${c.activeAssignmentsCount} tugas aktif',
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedCourierId = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Penanganan',
                        hintText:
                            'Contoh: Penerima sudah dihubungi ulang dan siap menerima paket...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Proses Resolusi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      widget.onHandleFailed(
        selectedAction,
        selectedCourierId,
        notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
    }
  }

  void _openCourierAssignmentModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CourierAssignmentDialog(
        shipmentId: widget.detail.id,
        nomorResi: widget.detail.nomorResi,
        currentCourierId: widget.detail.courierId,
        currentCourierName: widget.detail.courierNama,
        couriers: widget.couriers,
        onConfirmAssignment: widget.onAssignCourier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detail = widget.detail;
    final statusColor = AdminStatusHelper.getStatusColor(
      detail.statusKode,
      isDark: isDark,
    );
    final statusBg = AdminStatusHelper.getStatusBgColor(
      detail.statusKode,
      isDark: isDark,
    );
    final isTerminal = detail.statusKode.toUpperCase() == 'DELIVERED' ||
        detail.statusKode.toUpperCase() == 'CANCELLED';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Pengiriman
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
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
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
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                detail.statusNama,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Barcode: ${detail.barcodeValue} • Dibuat: ${AdminDateFormatter.formatDateTime(detail.createdAt)}',
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
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup Panel Detail',
                  ),
                ],
              ),
            ),

            // 2. Bar Tindakan Cepat Admin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Tindakan Operasional Admin:',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (detail.statusKode.toUpperCase() == 'PENDING')
                    FilledButton.icon(
                      onPressed: widget.isActionInProgress
                          ? null
                          : () => widget.onConfirmOrder(null),
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('Konfirmasi Pesanan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  if (!isTerminal)
                    FilledButton.tonalIcon(
                      onPressed: widget.isActionInProgress
                          ? null
                          : () => _openCourierAssignmentModal(context),
                      icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                      label: Text(
                        detail.hasActiveCourier
                            ? 'Ubah Penugasan Kurir'
                            : 'Tugaskan Kurir',
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: widget.isActionInProgress
                        ? null
                        : () => _showUpdateStatusModal(context),
                    icon: const Icon(Icons.sync_alt_rounded, size: 16),
                    label: const Text('Perbarui Status'),
                  ),
                  if (detail.statusKode.toUpperCase() == 'FAILED_DELIVERY' ||
                      detail.statusKode.toUpperCase() == 'RETURNED')
                    FilledButton.icon(
                      onPressed: widget.isActionInProgress
                          ? null
                          : () => _showFailedResolutionModal(context),
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        size: 16,
                      ),
                      label: const Text('Tangani Pengiriman Gagal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),

            // 3. Isi Konten Detail
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid Pengirim, Penerima, dan Akun Customer
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 680;
                        final cards = [
                          _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.person_pin_circle_rounded,
                            title: 'Identitas Pengirim & Asal',
                            rows: [
                              _InfoRow('Nama Pengirim', detail.pengirimNama),
                              _InfoRow('No. Telepon', detail.pengirimNoHp),
                              _InfoRow('Kota Asal', detail.pengirimKota),
                              _InfoRow('Alamat Lengkap', detail.pengirimAlamat),
                              if (detail.pengirimKodePos != null)
                                _InfoRow('Kode Pos', detail.pengirimKodePos!),
                              _InfoRow(
                                'Akun Customer (m_users)',
                                '${detail.customerNama} (${detail.customerEmail})',
                              ),
                            ],
                          ),
                          _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.location_on_rounded,
                            title: 'Identitas Penerima & Tujuan',
                            rows: [
                              _InfoRow('Nama Penerima', detail.penerimaNama),
                              _InfoRow('No. Telepon', detail.penerimaNoHp),
                              _InfoRow('Kota Tujuan', detail.penerimaKota),
                              _InfoRow('Alamat Lengkap', detail.penerimaAlamat),
                              if (detail.penerimaKodePos != null)
                                _InfoRow('Kode Pos', detail.penerimaKodePos!),
                            ],
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 16),
                            cards[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grid Spesifikasi Paket & Rincian Biaya Pembayaran
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 680;
                        final cards = [
                          _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.inventory_2_rounded,
                            title: 'Spesifikasi Paket & Layanan',
                            rows: [
                              _InfoRow(
                                'Jenis Layanan',
                                '${detail.serviceNama} (${detail.serviceKode})',
                              ),
                              if (detail.serviceEstimasi != null)
                                _InfoRow('Estimasi Layanan', detail.serviceEstimasi!),
                              _InfoRow(
                                'Berat Paket',
                                '${detail.totalBeratGram} gram (${(detail.totalBeratGram / 1000).toStringAsFixed(2)} kg)',
                              ),
                              _InfoRow(
                                'Dimensi (P x L x T)',
                                '${detail.panjangCm} x ${detail.lebarCm} x ${detail.tinggiCm} cm',
                              ),
                              _InfoRow('Jumlah Barang', '${detail.totalBarang} Koli / Pcs'),
                              if (detail.nilaiBarang != null)
                                _InfoRow(
                                  'Nilai Barang',
                                  AdminCurrencyFormatter.formatRupiah(
                                    detail.nilaiBarang,
                                  ),
                                ),
                              _InfoRow(
                                'Catatan Pengiriman',
                                detail.catatanPengiriman ?? '-',
                              ),
                            ],
                          ),
                          _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.payments_rounded,
                            title: 'Rincian Biaya & Pembayaran (t_shipment_payments)',
                            rows: [
                              _InfoRow(
                                'Metode Pembayaran',
                                detail.metodePembayaran.toUpperCase(),
                              ),
                              _InfoRow(
                                'Status Pembayaran',
                                AdminStatusHelper.getPaymentStatusLabel(
                                  detail.statusPembayaran,
                                ),
                              ),
                              if (detail.nomorPembayaran != null)
                                _InfoRow('No. Pembayaran', detail.nomorPembayaran!),
                              _InfoRow(
                                'Biaya Pengiriman Pokok',
                                AdminCurrencyFormatter.formatRupiah(
                                  detail.biayaPengiriman,
                                ),
                              ),
                              _InfoRow(
                                'Biaya Asuransi',
                                AdminCurrencyFormatter.formatRupiah(
                                  detail.biayaAsuransi,
                                ),
                              ),
                              _InfoRow(
                                'Biaya Layanan Tambahan',
                                AdminCurrencyFormatter.formatRupiah(
                                  detail.biayaLayananTambahan,
                                ),
                              ),
                              _InfoRow(
                                'Potongan Diskon',
                                '- ${AdminCurrencyFormatter.formatRupiah(detail.diskon)}',
                              ),
                              _InfoRow(
                                'Total Biaya Akhir',
                                AdminCurrencyFormatter.formatRupiah(
                                  detail.totalBiaya,
                                ),
                                isBold: true,
                              ),
                            ],
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 16),
                            cards[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Informasi Penugasan Kurir & Peta Lokasi Terakhir Kurir
                    _buildCourierAssignmentAndMapSection(context, isDark, detail),
                    const SizedBox(height: 16),

                    // Kronologi Perjalanan Paket (t_shipment_tracking)
                    _buildTrackingTimelineSection(isDark, detail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<_InfoRow> rows,
  }) {
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
                    child: Text(
                      r.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: r.isBold ? FontWeight.bold : FontWeight.w600,
                        color: r.isBold
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
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

  Widget _buildCourierAssignmentAndMapSection(
    BuildContext context,
    bool isDark,
    AdminDeliveryDetail detail,
  ) {
    final loc = detail.lastCourierLocation;
    final showMap = loc != null && detail.isCourierOnActiveDuty;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.two_wheeler_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Penugasan Kurir (t_shipment_assignments & m_employee)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _openCourierAssignmentModal(context),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  detail.hasActiveCourier ? 'Ubah Kurir' : 'Tugaskan Kurir',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!detail.hasActiveCourier)
            Text(
              'Belum ada kurir (id_users_role = 2) yang ditugaskan untuk pengiriman ini.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildBadgeStat(
                  'Nama Kurir',
                  '${detail.courierNama ?? "-"} (${detail.courierCode ?? "-"})',
                ),
                _buildBadgeStat('No. Telepon', detail.courierPhone ?? '-'),
                _buildBadgeStat('Email Kurir', detail.courierEmail ?? '-'),
                _buildBadgeStat(
                  'Waktu Ditugaskan',
                  AdminDateFormatter.formatDateTime(detail.assignedAt),
                ),
                if (detail.assignmentNotes != null &&
                    detail.assignmentNotes!.isNotEmpty)
                  _buildBadgeStat('Catatan Penugasan', detail.assignmentNotes!),
              ],
            ),
          if (showMap) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lokasi Terakhir Kurir Aktif (t_shipment_locations): '
                    '(${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}) '
                    '• Diperbarui: ${AdminDateFormatter.formatDateTime(loc.recordedAt)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(loc.latitude, loc.longitude),
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.satset.delivery',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(loc.latitude, loc.longitude),
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTrackingTimelineSection(
    bool isDark,
    AdminDeliveryDetail detail,
  ) {
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
                Icons.timeline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Kronologi Status Pengiriman (t_shipment_tracking)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (detail.trackingHistory.isEmpty)
            Text(
              'Belum ada riwayat perubahan status pada t_shipment_tracking.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detail.trackingHistory.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = detail.trackingHistory[index];
                final isLatest = index == 0;
                final color = AdminStatusHelper.getStatusColor(
                  item.statusCode,
                  isDark: isDark,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isLatest ? color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2.5),
                          ),
                        ),
                        if (index < detail.trackingHistory.length - 1)
                          Container(
                            width: 2,
                            height: 36,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.statusName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isLatest ? color : null,
                                ),
                              ),
                              Text(
                                AdminDateFormatter.formatDateTime(
                                  item.createdAt,
                                ),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          if (item.lokasiNama != null &&
                              item.lokasiNama!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Lokasi: ${item.lokasiNama}'
                              '${item.employeeName != null ? " • Petugas: ${item.employeeName}" : ""}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (item.catatan != null &&
                              item.catatan!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.catatan!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow(this.label, this.value, {this.isBold = false});
}

