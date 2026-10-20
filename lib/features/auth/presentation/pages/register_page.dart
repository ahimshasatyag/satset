import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../data/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Halaman Pendaftaran Akun Baru SatSet
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alamatController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final MapController _mapController = MapController();
  double _latitude = -6.2088; // Default awal: Jakarta
  double _longitude = 106.8456;
  bool _isLoadingLocation = false;

  static const List<Map<String, dynamic>> _quickCities = [
    {'name': 'Jakarta', 'lat': -6.2088, 'lng': 106.8456},
    {'name': 'Bandung', 'lat': -6.9175, 'lng': 107.6191},
    {'name': 'Surabaya', 'lat': -7.2575, 'lng': 112.7521},
    {'name': 'Semarang', 'lat': -6.9667, 'lng': 110.4167},
    {'name': 'Medan', 'lat': 3.5952, 'lng': 98.6722},
    {'name': 'Makassar', 'lat': -5.1477, 'lng': 119.4327},
  ];

  bool _hasPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage('assets/images/Background.png'), context);
    }
  }

  @override
  void initState() {
    super.initState();
    // Ambil posisi terakhir secara instan dari cache jika izin sudah ada, tanpa memblokir UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null && mounted) {
            setState(() {
              _latitude = lastKnown.latitude;
              _longitude = lastKnown.longitude;
            });
            _mapController.move(
              LatLng(lastKnown.latitude, lastKnown.longitude),
              15.0,
            );
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Mengambil lokasi pengguna saat ini (GPS) secara efisien tanpa freeze
  Future<void> _getCurrentLocation({bool showMessage = false}) async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // 1. Coba ambil posisi cache terakhir lebih dulu (sangat cepat & instan)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() {
            _latitude = lastKnown.latitude;
            _longitude = lastKnown.longitude;
          });
          _mapController.move(
            LatLng(lastKnown.latitude, lastKnown.longitude),
            15.0,
          );
        }
      } catch (_) {}

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Layanan lokasi (GPS) belum aktif. Silakan aktifkan GPS perangkat Anda.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && showMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi ditolak.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && showMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses lokasi ditolak permanen. Silakan aktifkan di Pengaturan.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Gunakan medium accuracy & timeout 4s agar hardware GPS emulator tidak hang
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );

        if (showMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi saat ini berhasil ditemukan!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      // Tetap gunakan koordinat yang ada secara aman tanpa force-close
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterSubmitted(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          alamatLengkap: _alamatController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background motif dari Background.png menutupi seluruh layar secara penuh
            Positioned.fill(
              child: Image.asset(
                'assets/images/Background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),

            // Lapisan overlay halus untuk mode gelap
            if (isDark)
              Positioned.fill(
                child: Container(
                  color: AppColors.backgroundDark.withValues(alpha: 0.85),
                ),
              ),

            SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    CustomDialog.showSuccess(
                      context: context,
                      title: 'Pendaftaran Berhasil!',
                      message:
                          'Selamat datang di SatSet.id, ${state.user.name}. Akun Anda siap digunakan.',
                      confirmText: 'Mulai Pengiriman',
                      onConfirm: () {
                        Navigator.pop(
                          context,
                        ); // Kembali ke login atau dashboard
                      },
                    );
                  } else if (state is AuthFailure) {
                    CustomDialog.showError(
                      context: context,
                      title: 'Pendaftaran Gagal',
                      message: state.errorMessage,
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CustomCard membungkus seluruh field formulir pendaftaran akun
                            CustomCard(
                              variant: CardVariant.elevated,
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon Ilustrasi Register & Judul
                                    Center(
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_add_rounded,
                                              size: 42,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Register',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.headlineSmall
                                                .copyWith(
                                                  color: isDark
                                                      ? AppColors
                                                            .textPrimaryDark
                                                      : AppColors
                                                            .textPrimaryLight,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Input Nama Lengkap
                                    CustomTextField(
                                      label: 'Nama Lengkap',
                                      hintText: 'Contoh: Budi Pratama',
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      isRequired: true,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                      validator: Validators.validateName,
                                    ),
                                    const SizedBox(height: 16),

                                    // Input Email
                                    CustomTextField(
                                      label: 'Alamat Email',
                                      hintText: 'nama@satset.id',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      isRequired: true,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.mail_outline_rounded,
                                      ),
                                      validator: Validators.validateEmail,
                                    ),
                                    const SizedBox(height: 16),

                                    // Input Nomor HP / WhatsApp
                                    CustomTextField(
                                      label: 'Nomor WhatsApp / HP',
                                      hintText: '081234567890',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      isRequired: true,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                      ),
                                      validator: Validators.validatePhone,
                                    ),
                                    const SizedBox(height: 16),

                                    // Input Alamat Lengkap
                                    CustomTextField(
                                      label: 'Alamat Lengkap',
                                      hintText: 'Contoh: Jl. Sudirman No. 45, RT 01/RW 02, Menteng',
                                      controller: _alamatController,
                                      keyboardType: TextInputType.streetAddress,
                                      textInputAction: TextInputAction.next,
                                      maxLines: 2,
                                      isRequired: true,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.home_outlined,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Alamat lengkap wajib diisi';
                                        }
                                        if (val.trim().length < 5) {
                                          return 'Alamat minimal 5 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Peta Penentuan Titik Koordinat
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.pin_drop_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Titik Koordinat (Maps)',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors
                                                          .textPrimaryLight,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '*',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        // Tombol Quick GPS Lokasi Saya
                                        InkWell(
                                          onTap: _isLoadingLocation
                                              ? null
                                              : () => _getCurrentLocation(
                                                  showMessage: true,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_isLoadingLocation)
                                                  const SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  )
                                                else
                                                  const Icon(
                                                    Icons.my_location_rounded,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Lokasi Saya',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Geser dan ketuk pada peta untuk menandai titik koordinat rumah atau kantor Anda.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Pilihan Cepat Kota
                                    SizedBox(
                                      height: 34,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _quickCities.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final city = _quickCities[index];
                                          final isSelected =
                                              (_latitude -
                                                          (city['lat']
                                                              as double))
                                                      .abs() <
                                                  0.05 &&
                                              (_longitude -
                                                          (city['lng']
                                                              as double))
                                                      .abs() <
                                                  0.05;
                                          return ActionChip(
                                            label: Text(city['name'] as String),
                                            labelStyle: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? AppColors
                                                              .textPrimaryDark
                                                        : AppColors
                                                              .textPrimaryLight),
                                            ),
                                            backgroundColor: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                      ? AppColors.surfaceDark
                                                      : AppColors.surfaceLight),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark
                                                        ? Colors.white12
                                                        : Colors.black12),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 0,
                                            ),
                                            onPressed: () {
                                              final lat = city['lat'] as double;
                                              final lng = city['lng'] as double;
                                              setState(() {
                                                _latitude = lat;
                                                _longitude = lng;
                                              });
                                              _mapController.move(
                                                LatLng(lat, lng),
                                                15.0,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Kontainer Peta Interaktif FlutterMap
                                    Container(
                                      height: 220,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.black12,
                                          width: 1.5,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          FlutterMap(
                                            mapController: _mapController,
                                            options: MapOptions(
                                              initialCenter: LatLng(
                                                _latitude,
                                                _longitude,
                                              ),
                                              initialZoom: 15.0,
                                              minZoom: 3.0,
                                              maxZoom: 18.0,
                                              interactionOptions:
                                                  const InteractionOptions(
                                                    flags:
                                                        InteractiveFlag.drag |
                                                        InteractiveFlag
                                                            .pinchZoom |
                                                        InteractiveFlag
                                                            .doubleTapZoom,
                                                  ),
                                              onTap: (tapPosition, point) {
                                                setState(() {
                                                  _latitude = point.latitude;
                                                  _longitude = point.longitude;
                                                });
                                              },
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                                                keepBuffer: 1,
                                                panBuffer: 0,
                                                userAgentPackageName:
                                                    'id.satset.app',
                                                tileProvider: NetworkTileProvider(
                                                  cachingProvider:
                                                      const DisabledMapCachingProvider(),
                                                  silenceExceptions: true,
                                                ),
                                              ),
                                              MarkerLayer(
                                                markers: [
                                                  Marker(
                                                    point: LatLng(
                                                      _latitude,
                                                      _longitude,
                                                    ),
                                                    width: 48,
                                                    height: 48,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: const Icon(
                                                      Icons.location_pin,
                                                      size: 44,
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          // Tombol Zoom In & Zoom Out & My Location
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Column(
                                              children: [
                                                Material(
                                                  color:
                                                      (isDark
                                                              ? AppColors
                                                                    .surfaceDark
                                                              : Colors.white)
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    side: BorderSide(
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black12,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () {
                                                      final currentZoom =
                                                          _mapController
                                                              .camera
                                                              .zoom;
                                                      _mapController.move(
                                                        _mapController
                                                            .camera
                                                            .center,
                                                        currentZoom + 1,
                                                      );
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Material(
                                                  color:
                                                      (isDark
                                                              ? AppColors
                                                                    .surfaceDark
                                                              : Colors.white)
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    side: BorderSide(
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black12,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () {
                                                      final currentZoom =
                                                          _mapController
                                                              .camera
                                                              .zoom;
                                                      _mapController.move(
                                                        _mapController
                                                            .camera
                                                            .center,
                                                        currentZoom - 1,
                                                      );
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Tombol GPS Lokasi Saya di dalam Map
                                                Material(
                                                  color:
                                                      (isDark
                                                              ? AppColors
                                                                    .surfaceDark
                                                              : Colors.white)
                                                          .withValues(
                                                            alpha: 0.95,
                                                          ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    side: BorderSide(
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black12,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: _isLoadingLocation
                                                        ? null
                                                        : () =>
                                                              _getCurrentLocation(
                                                                showMessage:
                                                                    true,
                                                              ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      child: _isLoadingLocation
                                                          ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .my_location_rounded,
                                                              size: 20,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Informasi interaksi di bawah peta
                                          Positioned(
                                            left: 10,
                                            right: 10,
                                            bottom: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.black87
                                                    : Colors.white.withValues(
                                                        alpha: 0.92,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.touch_app_outlined,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Ketuk peta untuk memindahkan pin lokasi',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Kartu Tampilan Koordinat (Lintang & Bujur)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.surfaceDark
                                                  : AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.black12,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Lintang (Latitude)',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? AppColors
                                                              .textSecondaryDark
                                                        : AppColors
                                                              .textSecondaryLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _latitude.toStringAsFixed(6),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.surfaceDark
                                                  : AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.black12,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bujur (Longitude)',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? AppColors
                                                              .textSecondaryDark
                                                        : AppColors
                                                              .textSecondaryLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _longitude.toStringAsFixed(6),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Input Kata Sandi
                                    CustomTextField(
                                      label: 'Kata Sandi',
                                      hintText: 'Minimal 8 karakter unik',
                                      controller: _passwordController,
                                      isPassword: true,
                                      isRequired: true,
                                      textInputAction: TextInputAction.next,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      validator: Validators.validatePassword,
                                    ),
                                    const SizedBox(height: 16),

                                    // Konfirmasi Kata Sandi
                                    CustomTextField(
                                      label: 'Ulangi Kata Sandi',
                                      hintText: 'Ketik ulang kata sandi Anda',
                                      controller: _confirmPasswordController,
                                      isPassword: true,
                                      isRequired: true,
                                      textInputAction: TextInputAction.done,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.lock_reset_rounded,
                                      ),
                                      onSubmitted: (_) => _handleSubmit(),
                                      validator: (val) {
                                        if (val != _passwordController.text) {
                                          return 'Konfirmasi kata sandi tidak cocok';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Tombol Daftar
                                    CustomButton(
                                      text: isLoading
                                          ? 'Memproses Pendaftaran...'
                                          : 'Daftar Sekarang',
                                      isLoading: isLoading,
                                      onPressed: isLoading
                                          ? null
                                          : _handleSubmit,
                                      prefixIcon: const Icon(
                                        Icons.how_to_reg_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Tautan ke Halaman Login
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sudah memiliki akun? ',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      'Masuk di Sini',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
