import 'dart:io';
import '../../domain/entities/delivery_proof_summary.dart';
import '../../domain/entities/task_status_detail.dart';
import '../../domain/entities/task_status_step.dart';
import '../../domain/repositories/courier_task_status_repository.dart';
import '../datasources/courier_task_status_local_datasource.dart';
import '../datasources/courier_task_status_remote_datasource.dart';

class CourierTaskStatusRepositoryImpl implements CourierTaskStatusRepository {
  final CourierTaskStatusRemoteDataSource remoteDataSource;
  final CourierTaskStatusLocalDataSource localDataSource;

  CourierTaskStatusRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<TaskStatusDetail> getTaskStatusDetail(
    String shipmentId, {
    String? courierId,
  }) async {
    try {
      final remoteData = await remoteDataSource.getTaskStatusDetail(
        shipmentId,
        courierId: courierId,
      );
      await localDataSource.cacheTaskDetail(remoteData);
      return remoteData;
    } on TaskNotFoundException {
      rethrow;
    } on TaskNotAssignedException {
      rethrow;
    } on SocketException {
      final cached = await localDataSource.getCachedTaskDetail(shipmentId);
      if (cached != null) return cached;
      throw const SocketException('Koneksi jaringan terputus. Pastikan perangkat terhubung internet.');
    } catch (e) {
      final cached = await localDataSource.getCachedTaskDetail(shipmentId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<TaskStatusStep>> getTaskTimeline(String shipmentId) async {
    return await remoteDataSource.getTaskTimeline(shipmentId);
  }

  @override
  Future<DeliveryProofSummary?> getTaskDeliveryProof(String shipmentId) async {
    return await remoteDataSource.getTaskDeliveryProof(shipmentId);
  }

  @override
  Future<void> updateTaskStatus({
    required String shipmentId,
    required String courierId,
    required int targetStatusId,
    required String targetStatusCode,
    String? notes,
    String? failureReason,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    await remoteDataSource.updateTaskStatus(
      shipmentId: shipmentId,
      courierId: courierId,
      targetStatusId: targetStatusId,
      targetStatusCode: targetStatusCode,
      notes: notes,
      failureReason: failureReason,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Stream<TaskStatusDetail> subscribeToTaskRealtime(String shipmentId) {
    return remoteDataSource.subscribeToTaskRealtime(shipmentId);
  }
}
