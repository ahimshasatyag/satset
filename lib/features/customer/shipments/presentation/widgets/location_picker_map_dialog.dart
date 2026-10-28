import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:satset/shared/theme/theme.dart';

/// Dialog Peta Interaktif untuk menentukan titik koordinat Latitude & Longitude
class LocationPickerMapDialog extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final String? initialCityName;

  const LocationPickerMapDialog({
    super.key,
    required this.title,
    this.initialLocation,
    this.initialCityName,
  });

  /// Navigasi helper untuk membuka pemilih titik peta
  static Future<LatLng?> show(
    BuildContext context, {
    required String title,
    LatLng? initialLocation,
    String? initialCityName,
  }) {
    return showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationPickerMapDialog(
        title: title,
        initialLocation: initialLocation,
        initialCityName: initialCityName,
      ),
    );
  }

  @override
  State<LocationPickerMapDialog> createState() =>
      _LocationPickerMapDialogState();
}

class _LocationPickerMapDialogState extends State<LocationPickerMapDialog> {
  late final MapController _mapController;
  late LatLng _selectedLocation;
  bool _isLoadingGps = false;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Inisialisasi titik koordinat awal
    if (widget.initialLocation != null &&
        widget.initialLocation!.latitude != 0.0 &&
        widget.initialLocation!.longitude != 0.0) {
      _selectedLocation = widget.initialLocation!;
    } else {
      _selectedLocation = _cityToLatLng(widget.initialCityName);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _cityToLatLng(String? city) {
    final c = (city ?? '').toLowerCase();
    if (c.contains('aceh')) {
      return const LatLng(5.5483, 95.3238);
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
    } else if (c.contains('balikpapan') || c.contains('samarinda') || c.contains('kalimantan')) {
      return const LatLng(-1.2379, 116.8529);
    }
    // Default Jakarta Pusat
    return const LatLng(-6.2088, 106.8456);
  }

  Future<void> _getCurrentDeviceLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );

        final target = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = target;
          _currentZoom = 16.5;
        });

        _mapController.move(target, 16.5);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi GPS tidak diberikan'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil GPS perangkat: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  void _zoomIn() {
    setState(() => _currentZoom = (_currentZoom + 1).clamp(4.0, 18.0));
    _mapController.move(_selectedLocation, _currentZoom);
  }

  void _zoomOut() {
    setState(() => _currentZoom = (_currentZoom - 1).clamp(4.0, 18.0));
    _mapController.move(_selectedLocation, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size.width,
        height: size.height * 0.78,
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC),
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ketuk peta atau geser untuk menentukan titik koordinat',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Kontainer Peta
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: _currentZoom,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom,
                      ),
                      onTap: (_, point) {
                        setState(() => _selectedLocation = point);
                        _mapController.move(point, _currentZoom);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                        userAgentPackageName: 'id.satset.delivery',
                        tileProvider: NetworkTileProvider(
                          cachingProvider: const DisabledMapCachingProvider(),
                          silenceExceptions: true,
                        ),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 60,
                            height: 60,
                            alignment: Alignment.topCenter,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  size: 46,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Badge Koordinat (Kiri Atas)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 70,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1B2A3D) : Colors.white)
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Koordinat Terpilih (Google Maps)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Lat: ${_selectedLocation.latitude.toStringAsFixed(8)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(8)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
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
                  ),

                  // Kontrol Zoom & My Location (Kanan Atas)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black87 : Colors.white)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
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
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 20),
                            onPressed: _zoomIn,
                            tooltip: 'Perbesar',
                          ),
                          Container(
                            height: 1,
                            width: 22,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 20),
                            onPressed: _zoomOut,
                            tooltip: 'Perkecil',
                          ),
                          Container(
                            height: 1,
                            width: 22,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          IconButton(
                            icon: _isLoadingGps
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                            onPressed: _isLoadingGps ? null : _getCurrentDeviceLocation,
                            tooltip: 'Gunakan Lokasi GPS Saya',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer / Tombol Konfirmasi Titik
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(_selectedLocation),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Konfirmasi Titik Ini',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
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
