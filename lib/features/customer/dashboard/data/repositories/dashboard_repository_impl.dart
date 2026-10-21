import '../../domain/entities/shipment.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<int> _ensureCustomerId(int? customerId) async {
    if (customerId != null && customerId > 0) return customerId;
    return await remoteDataSource.resolveCustomerId();
  }

  @override
  Stream<Shipment?> getLiveActiveShipmentStream({int? customerId}) async* {
    try {
      final cid = await _ensureCustomerId(customerId);
      yield* remoteDataSource.getLiveActiveShipmentStream(customerId: cid);
    } catch (_) {
      yield null;
    }
  }

  @override
  Future<Shipment?> getActiveShipment({int? customerId}) async {
    final cid = await _ensureCustomerId(customerId);
    return await remoteDataSource.getActiveShipment(customerId: cid);
  }

  @override
  Future<List<Shipment>> getRecentShipments({
    int? customerId,
    int limit = 10,
    String? statusFilter,
  }) async {
    final cid = await _ensureCustomerId(customerId);
    return await remoteDataSource.getRecentShipments(
      customerId: cid,
      limit: limit,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<ShipmentStatusSummary> getShipmentStatusSummary({int? customerId}) async {
    final cid = await _ensureCustomerId(customerId);
    return await remoteDataSource.getShipmentStatusSummary(customerId: cid);
  }

  @override
  Future<Shipment?> trackShipment(String trackingNumber) async {
    final result = await remoteDataSource.trackShipment(trackingNumber);
    if (result != null) {
      await localDataSource.addSearchHistory(trackingNumber);
    }
    return result;
  }

  @override
  Future<UserProfile> getUserProfile({String? userId}) async {
    final profile = await remoteDataSource.getUserProfile(userId: userId);
    final hasUnread = await localDataSource.hasUnreadNotifications();
    return profile.copyWith(hasUnreadCourierUpdates: hasUnread);
  }

  @override
  Future<List<String>> getSearchHistory() async {
    return await localDataSource.getSearchHistory();
  }

  @override
  Future<void> addSearchHistory(String trackingNumber) async {
    await localDataSource.addSearchHistory(trackingNumber);
  }

  @override
  Future<void> clearSearchHistory() async {
    await localDataSource.clearSearchHistory();
  }

  @override
  Future<void> markNotificationsAsRead() async {
    await remoteDataSource.markNotificationsAsRead();
    await localDataSource.setNotificationsRead(true);
  }
}
