import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackCourierCard extends StatelessWidget {
  final LiveTrackShipment shipment;
  final VoidCallback? onContactCourier;
  final VoidCallback? onViewBarcode;
  final VoidCallback? onViewDetails;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPreviousTracking;
  final VoidCallback? onNextTracking;

  const LiveTrackCourierCard({
    super.key,
    required this.shipment,
    this.onContactCourier,
    this.onViewBarcode,
    this.onViewDetails,
    this.currentIndex = 0,
    this.totalCount = 1,
    this.onPreviousTracking,
    this.onNextTracking,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCourier = shipment.courierName != null && shipment.courierName!.isNotEmpty;
    final isGpsLive = shipment.isCourierGpsAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Baris Navigasi Antar Tracking Paket (Arrow Kiri & Arrow Kanan)
          if (totalCount > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                    : AppColors.primary50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  // Sisi Kiri: Tombol Panah Kiri (Lihat Tracking Sebelumnya)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: onPreviousTracking != null
                          ? InkWell(
                              onTap: onPreviousTracking,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Tracking $currentIndex',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Sisi Tengah: Indikator Posisi Tracking (Contoh: "2 / 2")
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${currentIndex + 1} / $totalCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Indikator Titik (Dots)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          totalCount,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: idx == currentIndex ? 14 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: idx == currentIndex
                                  ? AppColors.primary
                                  : (isDark ? Colors.white30 : Colors.black26),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Sisi Kanan: Tombol Panah Kanan (Lihat Tracking Berikutnya)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: onNextTracking != null
                          ? InkWell(
                              onTap: onNextTracking,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tracking ${currentIndex + 2}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Baris Informasi Kurir & Status Pengiriman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          hasCourier
                              ? Icons.delivery_dining_rounded
                              : Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCourier ? shipment.courierName! : 'Kurir SatSet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shipment.courierVehicle ?? shipment.serviceTypeName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(shipment.statusCode, isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getStatusBorderColor(shipment.statusCode),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  shipment.statusName,
                  style: TextStyle(
                    color: _getStatusTextColor(shipment.statusCode),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Baris Nomor Resi, Tombol Salin, & Tombol Barcode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.tertiary900 : AppColors.tertiary50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor Resi',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        shipment.trackingNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol Salin Resi
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Salin Resi',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.primary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shipment.trackingNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nomor resi ${shipment.trackingNumber} disalin!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Tombol Lihat Barcode
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  tooltip: 'Lihat Barcode Paket',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  onPressed: onViewBarcode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Info Tujuan & Penerima
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tujuan: ${shipment.receiverName} • ${shipment.receiverAddress}, ${shipment.receiverCity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. Panel Status Lokasi & Estimasi
          if (isGpsLive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    color: AppColors.success,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shipment.distanceKm != null
                          ? '${shipment.distanceKm} km lagi (${shipment.etaMinutes ?? 15} mnt)'
                          : 'Posisi kurir aktif di rute pengantaran',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  Text(
                    shipment.locationFreshnessDescription,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shipment.isCompleted
                          ? 'Paket telah terkirim ke penerima'
                          : 'GPS Kurir belum aktif / paket sedang diproses',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 5. Tombol Aksi: Hubungi Kurir & Buka Detail/Timeline
          Row(
            children: [
              if (hasCourier && shipment.courierPhone != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContactCourier ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Nomor kurir: ${shipment.courierName} (${shipment.courierPhone})',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: const Text(
                      'Hubungi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: const Text(
                    'Riwayat & Detail',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getStatusBgColor(String code, bool isDark) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12);
      case 'OUT_FOR_DELIVERY':
      case 'IN_TRANSIT':
        return AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12);
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12);
      default:
        return isDark ? Colors.white10 : Colors.black12;
    }
  }

  static Color _getStatusBorderColor(String code) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success.withValues(alpha: 0.5);
      case 'OUT_FOR_DELIVERY':
      case 'IN_TRANSIT':
        return AppColors.primary.withValues(alpha: 0.5);
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return AppColors.secondary.withValues(alpha: 0.5);
      default:
        return Colors.transparent;
    }
  }

  static Color _getStatusTextColor(String code) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success;
      case 'OUT_FOR_DELIVERY':
      case 'IN_TRANSIT':
        return AppColors.primary;
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return AppColors.secondary;
      default:
        return AppColors.tertiary;
    }
  }
}
