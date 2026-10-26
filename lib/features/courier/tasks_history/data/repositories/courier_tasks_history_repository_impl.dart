import '../../domain/entities/courier_task_history_detail.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/entities/courier_task_history_stats.dart';
import '../../domain/repositories/courier_tasks_history_repository.dart';
import '../datasources/courier_tasks_history_local_datasource.dart';
import '../datasources/courier_tasks_history_remote_datasource.dart';

/// Implementasi repositori riwayat tugas kurir berbasis Clean Architecture
class CourierTasksHistoryRepositoryImpl
    implements CourierTasksHistoryRepository {
  final CourierTasksHistoryRemoteDataSource remoteDataSource;
  final CourierTasksHistoryLocalDataSource localDataSource;

  CourierTasksHistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<CourierTaskHistoryItem>> getHistoryTasks({
    String? courierId,
    CourierHistoryTaskType? taskType,
    String? statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final remoteTasks = await remoteDataSource.getHistoryTasks(
        courierId: courierId,
        taskType: taskType,
        statusCode: statusCode,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery,
        page: page,
        limit: limit,
      );

      // Cache halaman pertama jika tidak dalam pencarian query dinamis
      if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
        await localDataSource.cacheHistoryTasks(remoteTasks);
      }

      return remoteTasks;
    } catch (_) {
      // Offline fallback: muat dari cache lokal jika jaringan terputus
      final cached = await localDataSource.getCachedHistoryTasks();
      var filtered = cached;

      if (taskType != null && taskType != CourierHistoryTaskType.all) {
        filtered = filtered.where((t) => t.taskType == taskType).toList();
      }

      if (statusCode != null &&
          statusCode.trim().isNotEmpty &&
          statusCode.toUpperCase() != 'ALL') {
        final cleanStatus = statusCode.trim().toUpperCase();
        filtered = filtered
            .where((t) => t.statusCode.toUpperCase() == cleanStatus)
            .toList();
      }

      if (startDate != null) {
        final startDay =
            DateTime(startDate.year, startDate.month, startDate.day);
        filtered = filtered.where((t) {
          final time = t.primaryCompletionTime;
          return time.isAfter(startDay) || time.isAtSameMomentAs(startDay);
        }).toList();
      }

      if (endDate != null) {
        final endDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        filtered = filtered.where((t) {
          final time = t.primaryCompletionTime;
          return time.isBefore(endDay) || time.isAtSameMomentAs(endDay);
        }).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        filtered = filtered.where((t) {
          return t.trackingNumber.toLowerCase().contains(q) ||
              t.barcodeValue.toLowerCase().contains(q) ||
              t.receiverName.toLowerCase().contains(q) ||
              t.senderName.toLowerCase().contains(q);
        }).toList();
      }

      return filtered;
    }
  }

  @override
  Future<CourierTaskHistoryDetail> getHistoryDetail({
    required String shipmentId,
    required String taskId,
    String? courierId,
  }) async {
    // 1. Ambil task item dari cache atau list
    final cached = await localDataSource.getCachedHistoryTasks();
    CourierTaskHistoryItem? foundItem;
    for (final item in cached) {
      if (item.id == taskId || item.shipmentId == shipmentId) {
        foundItem = item;
        break;
      }
    }

    // 2. Ambil jejak kronologis pelacakan dari t_shipment_tracking
    final trackingTimeline =
        await remoteDataSource.getTrackingTimeline(shipmentId: shipmentId);

    // 3. Ambil bukti serah terima / pengiriman dari t_shipment_proofs
    final proofs = await remoteDataSource.getShipmentProofs(
      shipmentId: shipmentId,
      courierId: courierId,
    );

    // Jika item tidak ada di cache (mis. dibuka dari filter dalam), buat fallback item dari data pertama
    final taskItem = foundItem ??
        (await getHistoryTasks(
          courierId: courierId,
          searchQuery: shipmentId,
          limit: 1,
        ))
            .firstOrNull ??
        CourierTaskHistoryItem(
          id: taskId,
          shipmentId: shipmentId,
          courierId: courierId ?? '',
          trackingNumber: 'SST-$shipmentId',
          barcodeValue: 'SST-$shipmentId',
          taskType: CourierHistoryTaskType.delivery,
          statusId: 8,
          statusCode: 'DELIVERED',
          statusName: 'Paket Diterima',
          statusDescription: 'Pengiriman selesai',
          assignmentStatus: 'COMPLETED',
          senderName: 'Pengirim SatSet',
          senderPhone: '-',
          senderAddress: '-',
          senderCity: 'Indonesia',
          receiverName: 'Penerima SatSet',
          receiverPhone: '-',
          receiverAddress: '-',
          receiverCity: 'Indonesia',
          serviceTypeId: 1,
          serviceTypeName: 'Reguler',
          serviceTypeCode: 'REG',
          weightGram: 1000,
          itemName: 'Paket Pengiriman',
          itemValue: 0,
          totalFee: 0,
          paymentMethod: 'NON_COD',
          assignedAt: DateTime.now(),
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    return CourierTaskHistoryDetail(
      task: taskItem,
      trackingTimeline: trackingTimeline,
      proofs: proofs,
    );
  }

  @override
  Future<CourierTaskHistoryStats> getHistoryStats({String? courierId}) async {
    try {
      return await remoteDataSource.getHistoryStats(courierId: courierId);
    } catch (_) {
      final cached = await localDataSource.getCachedHistoryTasks();
      int total = cached.length;
      int completed = 0;
      int failed = 0;
      int returned = 0;
      int cancelled = 0;

      for (final t in cached) {
        final code = t.statusCode.toUpperCase();
        if (code == 'DELIVERED') {
          completed++;
        } else if (code == 'FAILED_DELIVERY') {
          failed++;
        } else if (code == 'RETURNED') {
          returned++;
        } else if (code == 'CANCELLED') {
          cancelled++;
        }
      }

      return CourierTaskHistoryStats(
        totalCount: total,
        completedCount: completed,
        failedCount: failed,
        returnedCount: returned,
        cancelledCount: cancelled,
      );
    }
  }
}
