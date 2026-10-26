import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/courier_tracking_task.dart';
import '../../domain/entities/tracking_service_status.dart';
import '../../domain/repositories/courier_location_tracking_repository.dart';
import '../../domain/usecases/check_location_permission_usecase.dart';
import '../../domain/usecases/get_active_courier_tasks_usecase.dart';
import '../../domain/usecases/get_current_courier_location_usecase.dart';
import '../../domain/usecases/send_courier_location_update_usecase.dart';
import '../../domain/usecases/stream_courier_location_usecase.dart';
import 'courier_location_tracking_event.dart';
import 'courier_location_tracking_state.dart';

class CourierLocationTrackingBloc
    extends Bloc<CourierLocationTrackingEvent, CourierLocationTrackingState> {
  final GetActiveCourierTasksUseCase getActiveCourierTasksUseCase;
  final GetCurrentCourierLocationUseCase getCurrentCourierLocationUseCase;
  final StreamCourierLocationUseCase streamCourierLocationUseCase;
  final SendCourierLocationUpdateUseCase sendCourierLocationUpdateUseCase;
  final CheckLocationPermissionUseCase checkLocationPermissionUseCase;
  final CourierLocationTrackingRepository repository;
  final String? courierId;

  StreamSubscription? _locationSubscription;
  DateTime? _lastBackendSyncTime;

  CourierLocationTrackingBloc({
    required this.getActiveCourierTasksUseCase,
    required this.getCurrentCourierLocationUseCase,
    required this.streamCourierLocationUseCase,
    required this.sendCourierLocationUpdateUseCase,
    required this.checkLocationPermissionUseCase,
    required this.repository,
    this.courierId,
  }) : super(const CourierLocationTrackingState()) {
    on<CourierLocationTrackingInitialized>(_onInitialized);
    on<CourierLocationTrackingStarted>(_onStarted);
    on<CourierLocationTrackingStopped>(_onStopped);
    on<CourierLocationTrackingTaskSelected>(_onTaskSelected);
    on<CourierLocationTrackingRefreshRequested>(_onRefreshRequested);
    on<CourierLocationPermissionRequested>(_onPermissionRequested);
    on<CourierLocationSettingsOpened>(_onSettingsOpened);
    on<CourierLocationUpdatedInternal>(_onLocationUpdatedInternal);
    on<CourierLocationErrorInternal>(_onErrorInternal);
    on<CourierGpsStatusChangedInternal>(_onGpsStatusChangedInternal);
  }

  Future<void> _onInitialized(
    CourierLocationTrackingInitialized event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // 1. Periksa izin lokasi dan ketersediaan hardware GPS
    final permStatus = await checkLocationPermissionUseCase.check();
    if (!permStatus.isServiceEnabled) {
      emit(state.copyWith(
        isLoading: false,
        gpsStatus: TrackingGpsStatus.gpsDisabled,
      ));
      return;
    }

    if (!permStatus.hasPermission) {
      emit(state.copyWith(
        isLoading: false,
        gpsStatus: TrackingGpsStatus.permissionDenied,
      ));
      return;
    }

    // 2. Muat daftar tugas aktif kurir
    final tasks = await _loadActiveTasks();
    if (tasks.isEmpty) {
      emit(state.copyWith(
        isLoading: false,
        activeTasks: const [],
        clearSelectedTask: true,
        gpsStatus: TrackingGpsStatus.noActiveTask,
      ));
      return;
    }

    final selected = state.selectedTask ?? tasks.first;
    final isTrackingPref = await repository.isTrackingEnabled();

    // 3. Ambil posisi awal kurir
    final initialLoc = await getCurrentCourierLocationUseCase();

    emit(state.copyWith(
      isLoading: false,
      activeTasks: tasks,
      selectedTask: selected,
      currentLocation: initialLoc,
      isTrackingEnabled: isTrackingPref,
      gpsStatus: isTrackingPref
          ? TrackingGpsStatus.active
          : TrackingGpsStatus.idle,
      lastUpdatedTime: initialLoc?.timestamp ?? DateTime.now(),
    ));

    // 4. Jika tracking aktif, mulai aliran GPS
    if (isTrackingPref) {
      _startLocationStream();
    }
  }

  Future<List<CourierTrackingTask>> _loadActiveTasks() async {
    try {
      return await getActiveCourierTasksUseCase(courierId: courierId);
    } catch (_) {
      return [];
    }
  }

  Future<void> _onStarted(
    CourierLocationTrackingStarted event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    final permStatus = await checkLocationPermissionUseCase.check();
    if (!permStatus.isServiceEnabled) {
      emit(state.copyWith(gpsStatus: TrackingGpsStatus.gpsDisabled));
      return;
    }

    if (!permStatus.hasPermission) {
      emit(state.copyWith(gpsStatus: TrackingGpsStatus.permissionDenied));
      return;
    }

    if (state.activeTasks.isEmpty) {
      emit(state.copyWith(gpsStatus: TrackingGpsStatus.noActiveTask));
      return;
    }

    await repository.setTrackingEnabled(true);
    emit(state.copyWith(
      isTrackingEnabled: true,
      gpsStatus: TrackingGpsStatus.active,
      successMessage: 'Pelacakan lokasi kurir aktif.',
    ));

    _startLocationStream();

    // Kirim posisi saat ini langsung jika tersedia
    if (state.currentLocation != null && state.selectedTask != null) {
      _sendLocationToBackend(
        state.selectedTask!,
        state.currentLocation!,
      );
    }
  }

  Future<void> _onStopped(
    CourierLocationTrackingStopped event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    await _stopLocationStream();
    await repository.setTrackingEnabled(false);

    emit(state.copyWith(
      isTrackingEnabled: false,
      gpsStatus: TrackingGpsStatus.paused,
      successMessage: 'Pelacakan lokasi dijeda.',
    ));
  }

  void _onTaskSelected(
    CourierLocationTrackingTaskSelected event,
    Emitter<CourierLocationTrackingState> emit,
  ) {
    emit(state.copyWith(selectedTask: event.task));

    // Kirim posisi saat ini ke pengiriman yang baru dipilih
    if (state.isTrackingEnabled && state.currentLocation != null) {
      _sendLocationToBackend(event.task, state.currentLocation!);
    }
  }

  Future<void> _onRefreshRequested(
    CourierLocationTrackingRefreshRequested event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final tasks = await _loadActiveTasks();
    final updatedLoc = await getCurrentCourierLocationUseCase();

    CourierTrackingTask? newSelected = state.selectedTask;
    if (tasks.isNotEmpty) {
      final stillExists = tasks.any((t) => t.taskId == newSelected?.taskId);
      if (!stillExists) {
        newSelected = tasks.first;
      }
    } else {
      newSelected = null;
    }

    final newStatus = tasks.isEmpty
        ? TrackingGpsStatus.noActiveTask
        : (state.isTrackingEnabled
            ? TrackingGpsStatus.active
            : TrackingGpsStatus.idle);

    emit(state.copyWith(
      isLoading: false,
      activeTasks: tasks,
      selectedTask: newSelected,
      clearSelectedTask: newSelected == null,
      currentLocation: updatedLoc ?? state.currentLocation,
      gpsStatus: newStatus,
      lastUpdatedTime: updatedLoc?.timestamp ?? DateTime.now(),
    ));

    if (state.isTrackingEnabled && updatedLoc != null && newSelected != null) {
      _sendLocationToBackend(newSelected, updatedLoc);
    }
  }

  Future<void> _onPermissionRequested(
    CourierLocationPermissionRequested event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    final granted = await checkLocationPermissionUseCase.request();
    if (granted) {
      add(const CourierLocationTrackingInitialized());
    } else {
      emit(state.copyWith(gpsStatus: TrackingGpsStatus.permissionDenied));
    }
  }

  Future<void> _onSettingsOpened(
    CourierLocationSettingsOpened event,
    Emitter<CourierLocationTrackingState> emit,
  ) async {
    await checkLocationPermissionUseCase.openSettings();
  }

  void _onLocationUpdatedInternal(
    CourierLocationUpdatedInternal event,
    Emitter<CourierLocationTrackingState> emit,
  ) {
    emit(state.copyWith(
      currentLocation: event.location,
      lastUpdatedTime: event.location.timestamp,
      gpsStatus: state.isTrackingEnabled
          ? TrackingGpsStatus.active
          : TrackingGpsStatus.idle,
    ));

    // Kirim pembaruan ke Supabase dengan interval frekuensi wajar (minimal 8-10 detik)
    if (state.isTrackingEnabled && state.selectedTask != null) {
      final now = DateTime.now();
      if (_lastBackendSyncTime == null ||
          now.difference(_lastBackendSyncTime!).inSeconds >= 8) {
        _sendLocationToBackend(state.selectedTask!, event.location);
      }
    }
  }

  void _onErrorInternal(
    CourierLocationErrorInternal event,
    Emitter<CourierLocationTrackingState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: event.message,
      gpsStatus: TrackingGpsStatus.error,
    ));
  }

  void _onGpsStatusChangedInternal(
    CourierGpsStatusChangedInternal event,
    Emitter<CourierLocationTrackingState> emit,
  ) {
    emit(state.copyWith(gpsStatus: event.status));
  }

  void _startLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = streamCourierLocationUseCase(distanceFilter: 10).listen(
      (location) {
        if (!isClosed) {
          add(CourierLocationUpdatedInternal(location));
        }
      },
      onError: (err) {
        if (!isClosed) {
          add(CourierLocationErrorInternal(err.toString()));
        }
      },
    );
  }

  Future<void> _stopLocationStream() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _sendLocationToBackend(
    CourierTrackingTask task,
    dynamic location,
  ) async {
    try {
      _lastBackendSyncTime = DateTime.now();
      await sendCourierLocationUpdateUseCase(
        shipmentId: task.shipmentId,
        courierId: task.courierId,
        location: location,
      );
    } catch (_) {
      // Kegagalan pengiriman sesaat tidak boleh mematahkan tracking lokal
    }
  }

  @override
  Future<void> close() async {
    await _stopLocationStream();
    return super.close();
  }
}
