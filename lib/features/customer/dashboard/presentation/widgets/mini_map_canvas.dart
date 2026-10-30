
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/shipment.dart';

class MiniMapCanvas extends StatefulWidget {
  final Shipment shipment;
  final double height;
  final VoidCallback? onFullScreenTap;

  const MiniMapCanvas({
    super.key,
    required this.shipment,
    this.height = 200,
    this.onFullScreenTap,
  });

  @override
  State<MiniMapCanvas> createState() => _MiniMapCanvasState();
}

class _MiniMapCanvasState extends State<MiniMapCanvas>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  Position? _devicePosition;
  double _currentZoom = 13.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _initDeviceLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
        if (mounted) {
          setState(() => _devicePosition = pos);
        }
      }
    } catch (_) {
      // Abaikan jika GPS izin belum diberikan atau timeout
    }
  }

  /// Menentukan koordinat tujuan (Penerima)
  LatLng _getDestinationLatLng() {
    if (widget.shipment.penerimaLatitude != null &&
        widget.shipment.penerimaLongitude != null &&
        widget.shipment.penerimaLatitude != 0.0) {
      return LatLng(
        widget.shipment.penerimaLatitude!,
        widget.shipment.penerimaLongitude!,
      );
    }
    return _cityToLatLng(widget.shipment.penerimaKota);
  }

  /// Menentukan koordinat awal (Pengirim)
  LatLng _getOriginLatLng() {
    if (widget.shipment.pengirimLatitude != null &&
        widget.shipment.pengirimLongitude != null &&
        widget.shipment.pengirimLatitude != 0.0) {
      return LatLng(
        widget.shipment.pengirimLatitude!,
        widget.shipment.pengirimLongitude!,
      );
    }
    return _cityToLatLng(widget.shipment.pengirimKota);
  }

  /// Menentukan posisi GPS kurir terkini
  LatLng _getCourierLatLng(LatLng origin, LatLng destination) {
    if (widget.shipment.courierPosition != null &&
        widget.shipment.courierPosition!.latitude != 0.0) {
      return LatLng(
        widget.shipment.courierPosition!.latitude,
        widget.shipment.courierPosition!.longitude,
      );
    }

    if (widget.shipment.courier != null &&
        widget.shipment.courier!.latitude != 0.0) {
      return LatLng(
        widget.shipment.courier!.latitude,
        widget.shipment.courier!.longitude,
      );
    }

    // Jika timeline memiliki titik koordinat terbaru
    if (widget.shipment.timeline.isNotEmpty) {
      for (final step in widget.shipment.timeline.reversed) {
        if (step.latitude != null &&
            step.longitude != null &&
            step.latitude != 0.0) {
          return LatLng(step.latitude!, step.longitude!);
        }
      }
    }

    // Jika kurir sedang aktif dan ada koordinat GPS perangkat
    if (_devicePosition != null &&
        widget.shipment.status == ShipmentStatus.outForDelivery) {
      return LatLng(_devicePosition!.latitude, _devicePosition!.longitude);
    }

    // Interpolasi posisi realistis sepanjang rute berdasarkan progres tahapan
    final progress = widget.shipment.progressPercentage.clamp(0.15, 0.85);
    final lat =
        origin.latitude + (destination.latitude - origin.latitude) * progress;
    final lng =
        origin.longitude +
        (destination.longitude - origin.longitude) * progress;
    return LatLng(lat, lng);
  }

  /// Pemetaan kota-kota besar Indonesia ke koordinat geografis nyata
  LatLng _cityToLatLng(String? city) {
    final c = (city ?? '').toLowerCase();
    if (c.contains('aceh')) {
      return const LatLng(5.5483, 95.3238); // Banda Aceh
    } else if (c.contains('medan') || c.contains('sumatera utara')) {
      return const LatLng(3.5952, 98.6722);
    } else if (c.contains('padang') || c.contains('sumatera barat')) {
      return const LatLng(-0.9471, 100.4172);
    } else if (c.contains('pekanbaru') || c.contains('riau')) {
      return const LatLng(0.5071, 101.4478);
    } else if (c.contains('palembang') || c.contains('sumatera selatan')) {
      return const LatLng(-2.9761, 104.7754);
    } else if (c.contains('lampung')) {
      return const LatLng(-5.4297, 105.2625);
    } else if (c.contains('bandung') || c.contains('jawa barat')) {
      return const LatLng(-6.9175, 107.6191);
    } else if (c.contains('semarang') || c.contains('jawa tengah')) {
      return const LatLng(-6.9667, 110.4167);
    } else if (c.contains('yogyakarta') || c.contains('jogja')) {
      return const LatLng(-7.7956, 110.3695);
    } else if (c.contains('surabaya') || c.contains('jawa timur')) {
      return const LatLng(-7.2575, 112.7521);
    } else if (c.contains('denpasar') || c.contains('bali')) {
      return const LatLng(-8.6705, 115.2126);
    } else if (c.contains('makassar') || c.contains('sulawesi')) {
      return const LatLng(-5.1477, 119.4327);
    } else if (c.contains('balikpapan') ||
        c.contains('samarinda') ||
        c.contains('kalimantan')) {
      return const LatLng(-1.2379, 116.8529);
    }
    // Default: Jakarta Pusat
    return const LatLng(-6.2088, 106.8456);
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(4.0, 18.0);
    });
    try {
      _mapController.move(_mapController.camera.center, _currentZoom);
    } catch (_) {}
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(4.0, 18.0);
    });
    try {
      _mapController.move(_mapController.camera.center, _currentZoom);
    } catch (_) {}
  }

  void _recenterToCourier(LatLng courierLatLng) {
    setState(() => _currentZoom = 14.5);
    try {
      _mapController.move(courierLatLng, 14.5);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final origin = _getOriginLatLng();
    final destination = _getDestinationLatLng();
    final courier = _getCourierLatLng(origin, destination);

    final distanceKm = widget.shipment.distanceKm > 0
        ? widget.shipment.distanceKm
        : (Geolocator.distanceBetween(
                    courier.latitude,
                    courier.longitude,
                    destination.latitude,
                    destination.longitude,
                  ) /
                  1000.0)
              .toStringAsFixed(1);


    final routePoints = [origin, courier, destination];

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2A) : const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Peta Nyata Berbasis OpenStreetMap (FlutterMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courier,
              initialZoom: _currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              // Tile Layer OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.satset.delivery',
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                  silenceExceptions: true,
                ),
              ),

              // Garis Rute Pengiriman Nyata (Polyline)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: AppColors.primary,
                    strokeWidth: 4.0,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Marker Layer (Titik Asal, Kurir Live, dan Tujuan)
              MarkerLayer(
                markers: [
                  // 1. Titik Pengirim (Asal)
                  Marker(
                    point: origin,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C3E50)
                            : const Color(0xFF475569),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warehouse_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // 2. Titik Tujuan (Penerima)
                  Marker(
                    point: destination,
                    width: 38,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // 3. Titik Kurir Real-Time dengan Denyut Animasi
                  Marker(
                    point: courier,
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Efek Radar Berdenyut
                            Container(
                              width: 36 + (_pulseController.value * 20),
                              height: 36 + (_pulseController.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary.withValues(
                                  alpha: (1.0 - _pulseController.value) * 0.4,
                                ),
                              ),
                            ),
                            // Avatar Icon Kurir Pengantar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Badge Real-Time GPS (Kiri Atas)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1B2A3D) : Colors.white)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(
                                alpha: 1.0 - _pulseController.value,
                              ),
                              blurRadius: 6 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPS REAL-TIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.white : AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kontrol Navigasi Mini-Map (Kanan Atas)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.black87 : Colors.white).withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Perbesar Peta',
                    onTap: _zoomIn,
                    isDark: isDark,
                  ),
                  Container(
                    height: 1,
                    width: 20,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildMapIconButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Perkecil Peta',
                    onTap: _zoomOut,
                    isDark: isDark,
                  ),
                  Container(
                    height: 1,
                    width: 20,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildMapIconButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Pusatkan ke Kurir',
                    onTap: () => _recenterToCourier(courier),
                    isDark: isDark,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Speed & Distance Indicator (Kiri Bawah)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black87 : Colors.white).withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.shipment.estimationDaysDisplay} • $distanceKm km ke tujuan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white70
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol Peta Penuh (Kanan Bawah)
          if (widget.onFullScreenTap != null)
            Positioned(
              bottom: 10,
              right: 10,
              child: InkWell(
                onTap: widget.onFullScreenTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Peta Penuh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
