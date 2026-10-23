import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_task.dart';

abstract class CourierTasksEvent extends Equatable {
  const CourierTasksEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat tugas kurir awal atau saat pull-to-refresh
class CourierTasksFetched extends CourierTasksEvent {
  final bool isRefresh;

  const CourierTasksFetched({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Memuat halaman berikutnya (infinite scroll pagination)
class CourierTasksLoadMore extends CourierTasksEvent {
  const CourierTasksLoadMore();
}

/// Mengubah query pencarian nomor resi / nama penerima
class CourierTasksSearchChanged extends CourierTasksEvent {
  final String query;

  const CourierTasksSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Mengubah tab kelompok tugas (Perlu Dikerjakan, Sedang Berlangsung, Selesai)
class CourierTasksGroupChanged extends CourierTasksEvent {
  final CourierTaskGroup group;

  const CourierTasksGroupChanged(this.group);

  @override
  List<Object?> get props => [group];
}

/// Mengubah filter jenis tugas (Semua, Pickup, Delivery)
class CourierTasksTypeFilterChanged extends CourierTasksEvent {
  final CourierTaskType? type;

  const CourierTasksTypeFilterChanged(this.type);

  @override
  List<Object?> get props => [type];
}

/// Memperbarui status alur tugas kurir (mis. PICKED_UP, OUT_FOR_DELIVERY, DELIVERED)
class CourierTaskStatusUpdated extends CourierTasksEvent {
  final String taskId;
  final String shipmentId;
  final String newStatusCode;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const CourierTaskStatusUpdated({
    required this.taskId,
    required this.shipmentId,
    required this.newStatusCode,
    this.notes,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        taskId,
        shipmentId,
        newStatusCode,
        notes,
        latitude,
        longitude,
      ];
}

/// Menerima pembaruan real-time dari Supabase
class CourierTasksRealtimeReceived extends CourierTasksEvent {
  final List<CourierTask> tasks;

  const CourierTasksRealtimeReceived(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

/// Memulai langganan real-time
class CourierTasksSubscriptionStarted extends CourierTasksEvent {
  const CourierTasksSubscriptionStarted();
}
