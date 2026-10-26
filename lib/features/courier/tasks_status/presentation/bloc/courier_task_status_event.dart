import 'package:equatable/equatable.dart';
import '../../domain/entities/status_transition_option.dart';
import '../../domain/entities/task_status_detail.dart';

abstract class CourierTaskStatusEvent extends Equatable {
  const CourierTaskStatusEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal halaman detail status tugas kurir
class CourierTaskStatusStarted extends CourierTaskStatusEvent {
  final String shipmentId;
  final String? courierId;

  const CourierTaskStatusStarted({
    required this.shipmentId,
    this.courierId,
  });

  @override
  List<Object?> get props => [shipmentId, courierId];
}

/// Menyegarkan data status dan timeline secara manual (pull-to-refresh)
class CourierTaskStatusRefreshed extends CourierTaskStatusEvent {
  const CourierTaskStatusRefreshed();
}

/// Event internal saat Supabase Realtime menerima data terbaru
class CourierTaskStatusRealtimeUpdated extends CourierTaskStatusEvent {
  final TaskStatusDetail updatedDetail;

  const CourierTaskStatusRealtimeUpdated(this.updatedDetail);

  @override
  List<Object?> get props => [updatedDetail];
}

/// Permintaan pembaruan status pengiriman oleh kurir
class CourierTaskStatusUpdateRequested extends CourierTaskStatusEvent {
  final StatusTransitionOption transition;
  final String? failureReason;
  final String? notes;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const CourierTaskStatusUpdateRequested({
    required this.transition,
    this.failureReason,
    this.notes,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        transition,
        failureReason,
        notes,
        locationName,
        latitude,
        longitude,
      ];
}

/// Reset status keberhasilan atau pesan galat setelah ditampilkan
class CourierTaskStatusFeedbackCleared extends CourierTaskStatusEvent {
  const CourierTaskStatusFeedbackCleared();
}
