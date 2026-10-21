import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackMap extends StatefulWidget {
  final bool isDark;
  final double pulseValue;
  final double zoomScale;
  final List<LiveTrackShipment> shipments;
  final int selectedIndex;
  final ValueChanged<int> onShipmentTapped;
  final MapController? mapController;

  const LiveTrackMap({
    super.key,
    required this.isDark,
    required this.pulseValue,
    required this.zoomScale,
    required this.shipments,
    required this.selectedIndex,
    required this.onShipmentTapped,
    this.mapController,
  });

  @override
  State<LiveTrackMap> createState() => _LiveTrackMapState();
}

class _LiveTrackMapState extends State<LiveTrackMap> {
  late MapController _internalMapController;
  MapController get _controller => widget.mapController ?? _internalMapController;

  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456); // Jakarta Pusat

  @override
  void initState() {
    super.initState();
    _internalMapController = MapController();
  }

  LiveTrackShipment? get _selectedShipment {
    if (widget.shipments.isEmpty) return null;
    if (widget.selectedIndex >= 0 && widget.selectedIndex < widget.shipments.length) {
      return widget.shipments[widget.selectedIndex];
    }
    return widget.shipments.first;
  }

  LatLng _determineCenter() {
    final sel = _selectedShipment;
    if (sel != null) {
      if (sel.isCourierGpsAvailable) {
        return LatLng(sel.courierLatitude!, sel.courierLongitude!);
      }
      if (sel.hasDestinationCoordinates) {
        return LatLng(sel.receiverLatitude!, sel.receiverLongitude!);
      }
      if (sel.senderLatitude != null && sel.senderLongitude != null) {
        return LatLng(sel.senderLatitude!, sel.senderLongitude!);
      }
    }
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedShipment;
    final initialCenter = _determineCenter();
    final isGpsLive = selected?.isCourierGpsAvailable ?? false;
    final hasDest = selected?.hasDestinationCoordinates ?? false;

    // Persiapkan markers
    final List<Marker> markers = [];
    final List<Polyline> polylines = [];

    // 1. Tambahkan marker untuk semua shipment lain
    for (int i = 0; i < widget.shipments.length; i++) {
      if (i == widget.selectedIndex) continue;
      final item = widget.shipments[i];

      if (item.isCourierGpsAvailable) {
        markers.add(
          Marker(
            point: LatLng(item.courierLatitude!, item.courierLongitude!),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => widget.onShipmentTapped(i),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.surfaceDark : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    // 2. Marker & Rute untuk shipment yang sedang dipilih
    if (selected != null) {
      // Titik Tujuan Pengiriman
      if (hasDest) {
        final destLatLng = LatLng(selected.receiverLatitude!, selected.receiverLongitude!);
        markers.add(
          Marker(
            point: destLatLng,
            width: 70,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.isDark ? AppColors.surfaceDark : Colors.white)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    selected.receiverName.split(' ').first,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 36,
                  height: 36,
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
                  child: const Center(
                    child: Icon(
                      Icons.home_rounded,
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

      // Titik Posisi Kurir Terkini
      if (isGpsLive) {
        final courierLatLng = LatLng(selected.courierLatitude!, selected.courierLongitude!);
        markers.add(
          Marker(
            point: courierLatLng,
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gelombang denyut radar lokasi live
                Container(
                  width: 50 + (widget.pulseValue * 18),
                  height: 50 + (widget.pulseValue * 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary
                        .withValues(alpha: (1.0 - widget.pulseValue) * 0.35),
                  ),
                ),
                // Avatar pin kurir aktif
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: (selected.courierHeading ?? 0.0) * (3.141592653589793 / 180),
                    child: const Center(
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Jika kedua koordinat kurir dan tujuan ada, gambar polyline rute garis lurus
        if (hasDest) {
          polylines.add(
            Polyline(
              points: [
                courierLatLng,
                LatLng(selected.receiverLatitude!, selected.receiverLongitude!),
              ],
              color: AppColors.primary,
              strokeWidth: 3.5,
              borderColor: Colors.white,
              borderStrokeWidth: 1.0,
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        // Kontainer Peta OSM FlutterMap
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.zoomScale,
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
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // Banner Transparan jika GPS Kurir Belum Tersedia (Bukan Mengarang Posisi!)
        if (selected != null && !isGpsLive && !selected.isCompleted)
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (widget.isDark ? AppColors.surfaceDark : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lokasi GPS Kurir Belum Tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDest
                              ? 'Peta menampilkan titik tujuan pengiriman Anda. Posisi kurir akan tampil saat kurir mengaktifkan navigasi.'
                              : 'Tugas kurir belum aktif atau izin GPS perangkat belum diberikan.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
