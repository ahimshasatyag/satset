import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/user_profile.dart';

class DashboardHeader extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLocationTap;

  const DashboardHeader({
    super.key,
    required this.profile,
    required this.onNotificationTap,
    this.onProfileTap,
    this.onLocationTap,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _currentLocationName;
  bool _isDetecting = false;
  bool _isGpsActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initDeviceLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Inisialisasi deteksi lokasi GPS saat ini secara non-blocking
  Future<void> _initDeviceLocation() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        final resolved = _resolveLocationFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (mounted) {
          setState(() {
            _currentLocationName = resolved;
            _isGpsActive = true;
          });
        }
      }
    } catch (_) {
      // Abaikan jika GPS gagal atau timeout, gunakan lokasi default profil
    }
  }

  /// Memperbarui lokasi GPS sekarang secara interaktif
  Future<void> _refreshLocation() async {
    if (widget.onLocationTap != null) {
      widget.onLocationTap!();
    }

    if (_isDetecting) return;
    setState(() => _isDetecting = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Layanan lokasi GPS nonaktif. Silakan aktifkan GPS perangkat.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi belum diberikan. Menampilkan lokasi perkiraan.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final resolved = _resolveLocationFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (mounted) {
        setState(() {
          _currentLocationName = resolved;
          _isGpsActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokasi sekarang diperbarui: $resolved',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat mengambil sinyal GPS. Menggunakan lokasi tersimpan.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  /// Menentukan nama kota terdekat dari koordinat GPS perangkat
  String _resolveLocationFromCoordinates(double lat, double lng) {
    const knownCities = [
      {'name': 'Jakarta Pusat', 'lat': -6.1805, 'lng': 106.8284},
      {'name': 'Jakarta Selatan', 'lat': -6.2615, 'lng': 106.8106},
      {'name': 'Jakarta Barat', 'lat': -6.1683, 'lng': 106.7589},
      {'name': 'Jakarta Timur', 'lat': -6.2250, 'lng': 106.9004},
      {'name': 'Jakarta Utara', 'lat': -6.1384, 'lng': 106.8640},
      {'name': 'Tangerang', 'lat': -6.1783, 'lng': 106.6319},
      {'name': 'Tangerang Selatan', 'lat': -6.2885, 'lng': 106.7179},
      {'name': 'Bekasi', 'lat': -6.2383, 'lng': 106.9756},
      {'name': 'Depok', 'lat': -6.4025, 'lng': 106.7942},
      {'name': 'Bogor', 'lat': -6.5971, 'lng': 106.8060},
      {'name': 'Bandung', 'lat': -6.9175, 'lng': 107.6191},
      {'name': 'Cimahi', 'lat': -6.8723, 'lng': 107.5420},
      {'name': 'Cirebon', 'lat': -6.7320, 'lng': 108.5523},
      {'name': 'Semarang', 'lat': -6.9667, 'lng': 110.4167},
      {'name': 'Yogyakarta', 'lat': -7.7956, 'lng': 110.3695},
      {'name': 'Surakarta', 'lat': -7.5755, 'lng': 110.8243},
      {'name': 'Surabaya', 'lat': -7.2575, 'lng': 112.7521},
      {'name': 'Sidoarjo', 'lat': -7.4478, 'lng': 112.7183},
      {'name': 'Malang', 'lat': -7.9666, 'lng': 112.6326},
      {'name': 'Denpasar', 'lat': -8.6705, 'lng': 115.2126},
      {'name': 'Medan', 'lat': 3.5952, 'lng': 98.6722},
      {'name': 'Palembang', 'lat': -2.9761, 'lng': 104.7754},
      {'name': 'Bandar Lampung', 'lat': -5.4297, 'lng': 105.2625},
      {'name': 'Padang', 'lat': -0.9471, 'lng': 100.4172},
      {'name': 'Pekanbaru', 'lat': 0.5071, 'lng': 101.4478},
      {'name': 'Banjarmasin', 'lat': -3.3194, 'lng': 114.5908},
      {'name': 'Balikpapan', 'lat': -1.2379, 'lng': 116.8529},
      {'name': 'Samarinda', 'lat': -0.5016, 'lng': 117.1537},
      {'name': 'Pontianak', 'lat': -0.0263, 'lng': 109.3425},
      {'name': 'Makassar', 'lat': -5.1477, 'lng': 119.4327},
      {'name': 'Manado', 'lat': 1.4748, 'lng': 124.8421},
    ];

    double minDistance = double.infinity;
    String closestCity = widget.profile.currentLocationDisplay;

    for (final city in knownCities) {
      final dist = Geolocator.distanceBetween(
        lat,
        lng,
        city['lat'] as double,
        city['lng'] as double,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestCity = city['name'] as String;
      }
    }

    if (minDistance < 50000) {
      return closestCity;
    }
    return widget.profile.currentLocationDisplay;
  }

  String get _displayLocationText {
    if (_isDetecting) return 'Mendeteksi GPS...';
    if (_currentLocationName != null && _currentLocationName!.isNotEmpty) {
      return _currentLocationName!;
    }
    return widget.profile.currentLocationDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Profil Pelanggan
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  child: widget.profile.avatarUrl.isNotEmpty
                      ? Image.network(
                          widget.profile.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Sapaan kepada pelanggan dari m_users & Titik Alamat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sapaan personal berbasis nama di m_users
                Text(
                  '${widget.profile.timeGreeting}, ${widget.profile.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Lokasi Sekarang Pelanggan (Bukan Alamat Rumah)
                Tooltip(
                  message: 'Lokasi Sekarang',
                  child: InkWell(
                    onTap: _refreshLocation,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: _isGpsActive
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _displayLocationText == 'Lokasi Sekarang'
                                  ? 'Lokasi Sekarang'
                                  : _displayLocationText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          if (_isDetecting)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lonceng Notifikasi dengan Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                  onPressed: widget.onNotificationTap,
                  tooltip: 'Pemberitahuan Status Paket',
                ),
              ),

              if (widget.profile.hasUnreadCourierUpdates &&
                  widget.profile.unreadCount > 0)
                PositionedDirectional(
                  top: 2,
                  end: 2,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.surfaceLight,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${widget.profile.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
