import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_task_history_item.dart';

abstract class CourierTasksHistoryEvent extends Equatable {
  const CourierTasksHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat atau memuat ulang (refresh) daftar riwayat tugas kurir
class CourierTaskHistoryFetched extends CourierTasksHistoryEvent {
  final bool isRefresh;

  const CourierTaskHistoryFetched({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Memuat halaman berikutnya untuk pagination tak hingga
class CourierTaskHistoryLoadMore extends CourierTasksHistoryEvent {
  const CourierTaskHistoryLoadMore();
}

/// Mengubah query pencarian resi / penerima
class CourierTaskHistorySearchChanged extends CourierTasksHistoryEvent {
  final String query;

  const CourierTaskHistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Mengubah filter rentang tanggal riwayat
class CourierTaskHistoryDateRangeChanged extends CourierTasksHistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? presetLabel;

  const CourierTaskHistoryDateRangeChanged({
    this.startDate,
    this.endDate,
    this.presetLabel,
  });

  @override
  List<Object?> get props => [startDate, endDate, presetLabel];
}

/// Mengubah filter jenis tugas (Semua, Pickup, Delivery)
class CourierTaskHistoryTaskTypeChanged extends CourierTasksHistoryEvent {
  final CourierHistoryTaskType taskType;

  const CourierTaskHistoryTaskTypeChanged(this.taskType);

  @override
  List<Object?> get props => [taskType];
}

/// Mengubah filter status (Semua, DELIVERED, FAILED_DELIVERY, RETURNED, CANCELLED)
class CourierTaskHistoryStatusFilterChanged extends CourierTasksHistoryEvent {
  final String statusCode;

  const CourierTaskHistoryStatusFilterChanged(this.statusCode);

  @override
  List<Object?> get props => [statusCode];
}

/// Mereset seluruh filter kembali ke kondisi awal
class CourierTaskHistoryFiltersReset extends CourierTasksHistoryEvent {
  const CourierTaskHistoryFiltersReset();
}

/// Meminta detail riwayat pengiriman (termasuk tracking & proofs)
class CourierTaskHistoryDetailRequested extends CourierTasksHistoryEvent {
  final String shipmentId;
  final String taskId;

  const CourierTaskHistoryDetailRequested({
    required this.shipmentId,
    required this.taskId,
  });

  @override
  List<Object?> get props => [shipmentId, taskId];
}

/// Menutup modal detail
class CourierTaskHistoryDetailDismissed extends CourierTasksHistoryEvent {
  const CourierTaskHistoryDetailDismissed();
}
