import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/courier_tracking_task.dart';
import '../../domain/entities/tracking_service_status.dart';

class CourierLocationTrackingState extends Equatable {
  final TrackingGpsStatus gpsStatus;
  final bool isTrackingEnabled;
  final List<CourierTrackingTask> activeTasks;
  final CourierTrackingTask? selectedTask;
  final CourierLocation? currentLocation;
  final CourierLocation? lastSavedLocation;
  final DateTime? lastUpdatedTime;
  final bool isLoading;
  final bool isSendingLocation;
  final String? errorMessage;
  final String? successMessage;

  const CourierLocationTrackingState({
    this.gpsStatus = TrackingGpsStatus.idle,
    this.isTrackingEnabled = false,
    this.activeTasks = const [],
    this.selectedTask,
    this.currentLocation,
    this.lastSavedLocation,
    this.lastUpdatedTime,
    this.isLoading = false,
    this.isSendingLocation = false,
    this.errorMessage,
    this.successMessage,
  });

  /// True jika kurir memiliki setidaknya satu tugas pengiriman aktif
  bool get hasActiveTasks => activeTasks.isNotEmpty;

  /// True jika koordinat GPS terkini valid dan tersedia
  bool get isGpsAvailable =>
      currentLocation != null && currentLocation!.isValid;

  /// True jika titik tujuan tugas aktif tersedia
  bool get hasDestinationCoordinates =>
      selectedTask != null && selectedTask!.hasTargetCoordinates;

  CourierLocationTrackingState copyWith({
    TrackingGpsStatus? gpsStatus,
    bool? isTrackingEnabled,
    List<CourierTrackingTask>? activeTasks,
    CourierTrackingTask? selectedTask,
    CourierLocation? currentLocation,
    CourierLocation? lastSavedLocation,
    DateTime? lastUpdatedTime,
    bool? isLoading,
    bool? isSendingLocation,
    String? errorMessage,
    String? successMessage,
    bool clearSelectedTask = false,
  }) {
    return CourierLocationTrackingState(
      gpsStatus: gpsStatus ?? this.gpsStatus,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      activeTasks: activeTasks ?? this.activeTasks,
      selectedTask:
          clearSelectedTask ? null : (selectedTask ?? this.selectedTask),
      currentLocation: currentLocation ?? this.currentLocation,
      lastSavedLocation: lastSavedLocation ?? this.lastSavedLocation,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      isLoading: isLoading ?? this.isLoading,
      isSendingLocation: isSendingLocation ?? this.isSendingLocation,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        gpsStatus,
        isTrackingEnabled,
        activeTasks,
        selectedTask,
        currentLocation,
        lastSavedLocation,
        lastUpdatedTime,
        isLoading,
        isSendingLocation,
        errorMessage,
        successMessage,
      ];
}
