import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/courier_tracking_task.dart';
import '../../domain/entities/tracking_service_status.dart';

abstract class CourierLocationTrackingEvent extends Equatable {
  const CourierLocationTrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal halaman pelacakan kurir
class CourierLocationTrackingInitialized extends CourierLocationTrackingEvent {
  const CourierLocationTrackingInitialized();
}

/// Menghidupkan mode pelacakan lokasi dan pengiriman berkala
class CourierLocationTrackingStarted extends CourierLocationTrackingEvent {
  const CourierLocationTrackingStarted();
}

/// Menghentikan pelacakan lokasi
class CourierLocationTrackingStopped extends CourierLocationTrackingEvent {
  const CourierLocationTrackingStopped();
}

/// Memilih tugas aktif pengiriman tertentu (jika ada lebih dari 1 tugas aktif)
class CourierLocationTrackingTaskSelected extends CourierLocationTrackingEvent {
  final CourierTrackingTask task;

  const CourierLocationTrackingTaskSelected(this.task);

  @override
  List<Object?> get props => [task];
}

/// Meminta pembaruan lokasi dan refresh tugas aktif secara manual
class CourierLocationTrackingRefreshRequested
    extends CourierLocationTrackingEvent {
  const CourierLocationTrackingRefreshRequested();
}

/// Meminta izin akses lokasi perangkat dari kurir
class CourierLocationPermissionRequested extends CourierLocationTrackingEvent {
  const CourierLocationPermissionRequested();
}

/// Membuka pengaturan sistem perangkat jika GPS nonaktif
class CourierLocationSettingsOpened extends CourierLocationTrackingEvent {
  const CourierLocationSettingsOpened();
}

/// Event internal saat lokasi baru diterima dari perangkat
class CourierLocationUpdatedInternal extends CourierLocationTrackingEvent {
  final CourierLocation location;

  const CourierLocationUpdatedInternal(this.location);

  @override
  List<Object?> get props => [location];
}

/// Event internal saat terjadi error pada aliran data lokasi
class CourierLocationErrorInternal extends CourierLocationTrackingEvent {
  final String message;

  const CourierLocationErrorInternal(this.message);

  @override
  List<Object?> get props => [message];
}

/// Event internal saat status GPS/perangkat berubah
class CourierGpsStatusChangedInternal extends CourierLocationTrackingEvent {
  final TrackingGpsStatus status;

  const CourierGpsStatusChangedInternal(this.status);

  @override
  List<Object?> get props => [status];
}
