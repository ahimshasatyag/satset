import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/courier_location_device_datasource.dart';
import '../../data/datasources/courier_location_local_datasource.dart';
import '../../data/datasources/courier_location_remote_datasource.dart';
import '../../data/repositories/courier_location_tracking_repository_impl.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/courier_tracking_task.dart';
import '../../domain/entities/tracking_service_status.dart';
import '../../domain/repositories/courier_location_tracking_repository.dart';
import '../../domain/usecases/check_location_permission_usecase.dart';
import '../../domain/usecases/get_active_courier_tasks_usecase.dart';
import '../../domain/usecases/get_current_courier_location_usecase.dart';
import '../../domain/usecases/send_courier_location_update_usecase.dart';
import '../../domain/usecases/stream_courier_location_usecase.dart';
import '../bloc/courier_location_tracking_bloc.dart';
import '../bloc/courier_location_tracking_event.dart';
import '../bloc/courier_location_tracking_state.dart';
import '../widgets/courier_active_task_card.dart';
import '../widgets/courier_location_map_view.dart';
import '../widgets/courier_location_permission_banner.dart';
import '../widgets/courier_tracking_controls.dart';
import '../widgets/courier_tracking_status_bar.dart';

/// Halaman utama Pelacakan Lokasi khusus Kurir pada aplikasi SatSet Delivery.
///
/// Halaman ini berfungsi untuk mengirim dan memantau koordinat GPS kurir secara
/// realtime selama kurir menjalankan tugas pickup atau pengantaran yang aktif.
/// Koordinat disimpan pada `t_shipment_locations` dan dipublikasikan via Supabase Realtime
/// untuk dilacak oleh customer maupun dimonitor oleh admin operasional.
class CourierLocationTrackingPage extends StatefulWidget {
  final User? user;
  final String? courierId;
  final CourierLocationTrackingRepository? repository;
  final CourierLocationTrackingBloc? bloc;

  const CourierLocationTrackingPage({
    super.key,
    this.user,
    this.courierId,
    this.repository,
    this.bloc,
  });

  @override
  State<CourierLocationTrackingPage> createState() => _CourierLocationTrackingPageState();
}

class _CourierLocationTrackingPageState extends State<CourierLocationTrackingPage>
    with SingleTickerProviderStateMixin {
  late final CourierLocationTrackingBloc _bloc;
  late final MapController _mapController;
  late final AnimationController _pulseController;

  bool _hasInitiallyCentered = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      final repo = widget.repository ??
          CourierLocationTrackingRepositoryImpl(
            remoteDataSource: CourierLocationRemoteDataSourceImpl(
              client: Supabase.instance.client,
              currentUser: widget.user,
            ),
            deviceDataSource: CourierLocationDeviceDataSourceImpl(),
            localDataSource: CourierLocationLocalDataSourceImpl(),
          );

      _bloc = CourierLocationTrackingBloc(
        getActiveCourierTasksUseCase: GetActiveCourierTasksUseCase(repo),
        getCurrentCourierLocationUseCase: GetCurrentCourierLocationUseCase(repo),
        streamCourierLocationUseCase: StreamCourierLocationUseCase(repo),
        sendCourierLocationUpdateUseCase: SendCourierLocationUpdateUseCase(repo),
        checkLocationPermissionUseCase: CheckLocationPermissionUseCase(repo),
        repository: repo,
        courierId: widget.courierId,
      );
    }

    _bloc.add(const CourierLocationTrackingInitialized());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1.0).clamp(3.0, 18.0),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1.0).clamp(3.0, 18.0),
    );
  }

  void _centerOnCourier(CourierLocation? loc) {
    if (loc != null && loc.isValid) {
      _mapController.move(LatLng(loc.latitude, loc.longitude), 16.0);
    }
  }

  void _centerOnDestination(CourierTrackingTask? task) {
    if (task != null && task.hasTargetCoordinates) {
      _mapController.move(LatLng(task.targetLatitude!, task.targetLongitude!), 16.0);
    }
  }

  void _fitBounds(CourierLocation? loc, CourierTrackingTask? task) {
    if (loc != null && loc.isValid && task != null && task.hasTargetCoordinates) {
      final courierPoint = LatLng(loc.latitude, loc.longitude);
      final targetPoint = LatLng(task.targetLatitude!, task.targetLongitude!);
      final bounds = LatLngBounds(courierPoint, targetPoint);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 100,
            bottom: 240,
            left: 50,
            right: 50,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CourierLocationTrackingBloc, CourierLocationTrackingState>(
        listener: (context, state) {
          // Tampilkan pesan error jika ada
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Otomatis pusatkan kamera pada pembaruan lokasi pertama
          if (!_hasInitiallyCentered && state.currentLocation != null && state.currentLocation!.isValid) {
            _hasInitiallyCentered = true;
            _centerOnCourier(state.currentLocation);
          }
        },
        builder: (context, state) {
          final selectedTask = state.selectedTask;
          final currentLocation = state.currentLocation;
          final isTrackingActive = state.isTrackingEnabled;
          final isPermissionIssue = state.gpsStatus == TrackingGpsStatus.permissionDenied ||
              state.gpsStatus == TrackingGpsStatus.permissionDeniedForever ||
              state.gpsStatus == TrackingGpsStatus.gpsDisabled;

          return Scaffold(
            body: Stack(
              children: [
                // 1. Tampilan Peta Interaktif Layar Penuh
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CourierLocationMapView(
                      mapController: _mapController,
                      currentLocation: currentLocation,
                      selectedTask: selectedTask,
                      isTrackingActive: isTrackingActive,
                      pulseValue: _pulseController.value,
                      isDark: isDark,
                      onRecenterCourier: () => _centerOnCourier(currentLocation),
                    );
                  },
                ),

                // 2. Bar Status GPS & Akurasi (Bagian Atas Peta)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: CourierTrackingStatusBar(
                    status: state.gpsStatus,
                    location: currentLocation,
                    lastUpdatedTime: state.lastUpdatedTime,
                    onRefresh: () {
                      _bloc.add(const CourierLocationTrackingRefreshRequested());
                    },
                  ),
                ),

                // 3. Banner Izin Lokasi & Layanan GPS (Jika Dinonaktifkan atau Ditolak)
                if (isPermissionIssue)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 16,
                    right: 16,
                    child: CourierLocationPermissionBanner(
                      status: state.gpsStatus,
                      onRequestPermission: () {
                        _bloc.add(const CourierLocationPermissionRequested());
                      },
                      onOpenSettings: () {
                        _bloc.add(const CourierLocationSettingsOpened());
                      },
                    ),
                  ),

                // 4. Kontrol Mengambang Peta: Zoom, Pusatkan Kurir, Pusatkan Tujuan, Fit Bounds
                Positioned(
                  top: MediaQuery.of(context).padding.top + 86,
                  right: 16,
                  child: CourierTrackingControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onCenterCourier: () => _centerOnCourier(currentLocation),
                    onCenterDestination: selectedTask != null && selectedTask.hasTargetCoordinates
                        ? () => _centerOnDestination(selectedTask)
                        : null,
                    onFitBounds: (currentLocation != null &&
                            currentLocation.isValid &&
                            selectedTask != null &&
                            selectedTask.hasTargetCoordinates)
                        ? () => _fitBounds(currentLocation, selectedTask)
                        : null,
                    isCourierLocationAvailable: currentLocation != null && currentLocation.isValid,
                    isDestinationAvailable: selectedTask != null && selectedTask.hasTargetCoordinates,
                  ),
                ),

                // 5. Bagian Bawah: Kartu Tugas Aktif atau Pesan Tidak Ada Tugas
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: state.hasActiveTasks && selectedTask != null
                      ? CourierActiveTaskCard(
                          task: selectedTask,
                          allActiveTasks: state.activeTasks,
                          isTrackingActive: isTrackingActive,
                          onToggleTracking: (enabled) {
                            if (enabled) {
                              _bloc.add(const CourierLocationTrackingStarted());
                            } else {
                              _bloc.add(const CourierLocationTrackingStopped());
                            }
                          },
                          onSelectTask: (task) {
                            _bloc.add(CourierLocationTrackingTaskSelected(task));
                            if (task.hasTargetCoordinates) {
                              _centerOnDestination(task);
                            }
                          },
                        )
                      : _buildNoActiveTasksCard(context, isDark, state.isLoading),
                ),

                // 6. Indikator Loading Awal
                if (state.isLoading && state.activeTasks.isEmpty)
                  Positioned.fill(
                    child: Container(
                      color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                          .withValues(alpha: 0.65),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tampilan kartu informatif jika kurir tidak memiliki tugas aktif
  Widget _buildNoActiveTasksCard(BuildContext context, bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tidak Ada Tugas Aktif',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pelacakan GPS dihentikan otomatis untuk menghemat baterai & menjaga privasi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(isLoading ? 'Memeriksa Tugas...' : 'Periksa Tugas Baru'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      _bloc.add(const CourierLocationTrackingRefreshRequested());
                    },
            ),
          ),
        ],
      ),
    );
  }
}
