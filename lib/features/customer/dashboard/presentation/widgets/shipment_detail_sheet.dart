import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/shipment.dart';
import 'courier_contact_sheet.dart';
import 'mini_map_canvas.dart';

class ShipmentDetailSheet extends StatelessWidget {
  final Shipment shipment;

  const ShipmentDetailSheet({
    super.key,
    required this.shipment,
  });

  static void show(BuildContext context, Shipment shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShipmentDetailSheet(shipment: shipment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            shipment.nomorResi,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: shipment.nomorResi));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nomor resi berhasil disalin ke clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Layanan: ${shipment.serviceName} • Dibuat: ${shipment.formattedCreatedAt}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(shipment),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tampilan Barcode Paket
                  _buildBarcodeCard(context, isDark),
                  const SizedBox(height: 18),

                  // 2. Informasi Paket
                  _buildPackageInfoSection(context, isDark),
                  const SizedBox(height: 18),

                  // 3. Informasi Pengirim & Penerima
                  _buildAddressSection(context, isDark),
                  const SizedBox(height: 18),

                  // 4. Pelacakan Lokasi Kurir jika tersedia
                  if (shipment.courier != null || (shipment.courierPosition?.latitude != null && shipment.courierPosition!.latitude != 0.0)) ...[
                    _buildCourierTrackingSection(context, isDark),
                    const SizedBox(height: 18),
                  ],

                  // 5. Timeline Perjalanan dari t_shipment_tracking
                  _buildTimelineSection(context, isDark),
                  const SizedBox(height: 24),

                  // Tombol Tutup
                  CustomButton(
                    text: 'Tutup Detail Pengiriman',
                    isFullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162232) : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 50),
            painter: _BarcodePainter(
              value: shipment.barcodeValue.isNotEmpty ? shipment.barcodeValue : shipment.nomorResi,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shipment.barcodeValue.isNotEmpty ? shipment.barcodeValue : shipment.nomorResi,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pindai barcode ini pada loket atau kurir SatSet untuk verifikasi',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfoSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Informasi Paket & Biaya',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Jenis Layanan', shipment.serviceName, isDark),
          _buildInfoRow('Total Berat', shipment.formattedTotalBerat, isDark),
          _buildInfoRow('Jumlah Barang', '${shipment.totalBarang} item', isDark),
          if (shipment.catatanPengiriman != null && shipment.catatanPengiriman!.isNotEmpty)
            _buildInfoRow('Catatan', shipment.catatanPengiriman!, isDark),
          _buildInfoRow('Metode Pembayaran', shipment.metodePembayaran, isDark),
          _buildInfoRow('Total Biaya', shipment.formattedTotalBiaya, isDark, isBoldValue: true),
          if (shipment.estimasiTiba != null)
            _buildInfoRow('Estimasi Waktu Tiba', shipment.etaDisplay, isDark, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pengirim
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.outbox_rounded, size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengirim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      '${shipment.pengirimNama} (${shipment.pengirimNoHp})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${shipment.pengirimAlamat}, ${shipment.pengirimKota}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          // Penerima
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Penerima', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      '${shipment.penerimaNama} (${shipment.penerimaNoHp})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${shipment.penerimaAlamat}, ${shipment.penerimaKota}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

  Widget _buildCourierTrackingSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_bike_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Informasi Pelacakan Lokasi Kurir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (shipment.courier != null)
                InkWell(
                  onTap: () {
                    CourierContactSheet.show(context, courier: shipment.courier!);
                  },
                  child: const Text(
                    'Hubungi Kurir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          MiniMapCanvas(
            shipment: shipment,
            height: 160,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, bool isDark) {
    final timeline = shipment.timeline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Timeline Perjalanan Paket (t_shipment_tracking)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (timeline.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 3),
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
                        Text(
                          shipment.statusName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Paket terdaftar di sistem SatSet pada ${shipment.formattedCreatedAt}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              separatorBuilder: (_, index) => Container(
                margin: const EdgeInsets.only(left: 5),
                height: 20,
                width: 2,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final step = timeline[timeline.length - 1 - index]; // terbaru di atas
                final isLatest = index == 0;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: isLatest ? AppColors.primary : AppColors.success,
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
                              Text(
                                step.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isLatest ? AppColors.primary : null,
                                ),
                              ),
                              Text(
                                '${step.timestamp.day}/${step.timestamp.month} ${step.timestamp.hour.toString().padLeft(2, '0')}:${step.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (step.location != null && step.location!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Lokasi: ${step.location}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondary,
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

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool isBoldValue = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: (isBoldValue || isHighlight) ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? AppColors.secondary
                  : (isBoldValue
                      ? AppColors.primary
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Shipment shipment) {
    if (shipment.isDelivered) {
      return StatusBadge.success(label: shipment.statusName);
    } else if (shipment.isInTransit) {
      return StatusBadge(label: shipment.statusName, status: BadgeStatus.info);
    } else if (shipment.isInProcess) {
      return StatusBadge.satset(label: shipment.statusName);
    } else {
      return StatusBadge(label: shipment.statusName, status: BadgeStatus.warning);
    }
  }
}

class _BarcodePainter extends CustomPainter {
  final String value;
  final bool isDark;

  _BarcodePainter({required this.value, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;

    final bytes = value.codeUnits;
    if (bytes.isEmpty) return;

    final double barWidth = size.width / (bytes.length * 3 + 10);
    double currentX = 5.0;

    for (int i = 0; i < bytes.length; i++) {
      final code = bytes[i];
      final w1 = (code % 2 == 0) ? barWidth * 1.5 : barWidth * 0.8;
      final w2 = (code % 3 == 0) ? barWidth * 2.0 : barWidth * 1.0;

      canvas.drawRect(Rect.fromLTWH(currentX, 0, w1, size.height), paint);
      currentX += w1 + barWidth;

      canvas.drawRect(Rect.fromLTWH(currentX, 0, w2, size.height), paint);
      currentX += w2 + barWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isDark != isDark;
  }
}
