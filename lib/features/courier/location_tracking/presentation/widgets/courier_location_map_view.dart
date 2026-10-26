import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/courier_tracking_task.dart';

/// Peta interaktif khusus kurir menggunakan FlutterMap (OpenStreetMap).
/// Menampilkan:
/// 1. Posisi GPS terkini kurir dengan indikator radar aktif & rotasi heading.
/// 2. Titik tujuan (pengantaran) atau titik asal (pickup) jika koordinat tersedia di database.
/// 3. Garis panduan rute (polyline) antara posisi kurir dan titik tujuan.
/// 4. Akurasi GPS visual (lingkaran akurasi).
/// 5. Tidak memalsukan atau mengarang posisi dummy apabila GPS belum diperoleh.
class CourierLocationMapView extends StatelessWidget {
  final MapController mapController;
  final CourierLocation? currentLocation;
  final CourierTrackingTask? selectedTask;
  final bool isTrackingActive;
  final double pulseValue;
  final bool isDark;
  final VoidCallback? onRecenterCourier;

  // Koordinat fallback default: Monas / Jakarta Pusat (hanya jika GPS kurir belum ada sama sekali)
  static const LatLng defaultCenter = LatLng(-6.2088, 106.8456);

  const CourierLocationMapView({
    super.key,
    required this.mapController,
    required this.currentLocation,
    required this.selectedTask,
    required this.isTrackingActive,
    required this.pulseValue,
    required this.isDark,
    this.onRecenterCourier,
  });

  LatLng get _initialCenter {
    if (currentLocation != null && currentLocation!.isValid) {
      return LatLng(currentLocation!.latitude, currentLocation!.longitude);
    }
    if (selectedTask != null && selectedTask!.hasTargetCoordinates) {
      return LatLng(selectedTask!.targetLatitude!, selectedTask!.targetLongitude!);
    }
    return defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [];
    final List<Polyline> polylines = [];
    final List<CircleMarker> circleMarkers = [];

    final hasCourierPosition = currentLocation != null && currentLocation!.isValid;
    final hasTaskTarget = selectedTask != null && selectedTask!.hasTargetCoordinates;

    LatLng? courierLatLng;
    LatLng? targetLatLng;

    // 1. Koordinat Target Tugas (Pickup atau Delivery)
    if (hasTaskTarget) {
      targetLatLng = LatLng(selectedTask!.targetLatitude!, selectedTask!.targetLongitude!);
      final isPickup = selectedTask!.isPickup;
      final targetLabel = isPickup ? 'Titik Pickup' : 'Titik Tujuan';
      final targetName = isPickup
          ? selectedTask!.senderName.split(' ').first
          : selectedTask!.receiverName.split(' ').first;

      markers.add(
        Marker(
          point: targetLatLng,
          width: 90,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label Nama Penerima / Pengirim
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$targetLabel: $targetName',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              // Pin Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isPickup ? Icons.inventory_2_rounded : Icons.home_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Koordinat Posisi Kurir Terkini
    if (hasCourierPosition) {
      courierLatLng = LatLng(currentLocation!.latitude, currentLocation!.longitude);

      // Lingkaran Akurasi GPS (visual radius dalam meter)
      if (currentLocation!.accuracy != null &&
          currentLocation!.accuracy! > 0 &&
          currentLocation!.accuracy! < 200) {
        circleMarkers.add(
          CircleMarker(
            point: courierLatLng,
            radius: currentLocation!.accuracy!,
            useRadiusInMeter: true,
            color: AppColors.primary.withValues(alpha: 0.10),
            borderColor: AppColors.primary.withValues(alpha: 0.35),
            borderStrokeWidth: 1.2,
          ),
        );
      }

      final hasHeading = currentLocation!.heading != null && currentLocation!.heading! >= 0;
      final headingDegrees = hasHeading ? currentLocation!.heading! : 0.0;
      final headingRadians = (headingDegrees * math.pi) / 180.0;

      markers.add(
        Marker(
          point: courierLatLng,
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gelombang denyut radar lokasi aktif saat tracking menyala
              if (isTrackingActive)
                Container(
                  width: 50 + (pulseValue * 22),
                  height: 50 + (pulseValue * 22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: (1.0 - pulseValue) * 0.35),
                  ),
                ),

              // Indikator arah hadap (heading arrow) jika didukung perangkat
              if (hasHeading && isTrackingActive)
                Transform.rotate(
                  angle: headingRadians,
                  child: Transform.translate(
                    offset: const Offset(0, -26),
                    child: const Icon(
                      Icons.navigation_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),

              // Pin Kurir Aktif
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.motorcycle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),

              // Badge kecil "Saya"
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    'Saya',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Garis Hubung (Polyline) antara Posisi Kurir dan Titik Tujuan
    if (courierLatLng != null && targetLatLng != null) {
      polylines.add(
        Polyline(
          points: [courierLatLng, targetLatLng],
          color: AppColors.primary,
          strokeWidth: 3.5,
          borderColor: Colors.white,
          borderStrokeWidth: 1.0,
        ),
      );
    }

    return Stack(
      children: [
        // Area Peta FlutterMap OSM
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
              keepBuffer: 2,
              panBuffer: 1,
              userAgentPackageName: 'id.satset.delivery',
              tileProvider: NetworkTileProvider(
                cachingProvider: const DisabledMapCachingProvider(),
                silenceExceptions: true,
              ),
            ),
            if (circleMarkers.isNotEmpty) CircleLayer(circles: circleMarkers),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // Banner Status GPS Belum Tersedia (Bukan Mengarang Posisi)
        if (!hasCourierPosition)
          Positioned(
            top: 14,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu sinyal koordinat GPS aktual...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
