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

  @override
  Stream<Shipment> getLiveActiveShipmentStream() {
    return remoteDataSource.getLiveActiveShipmentStream();
  }

  @override
  Future<Shipment> getActiveShipment() async {
    return await remoteDataSource.getActiveShipment();
  }

  @override
  Future<List<Shipment>> getRecentShipments() async {
    return await remoteDataSource.getRecentShipments();
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
  Future<UserProfile> getUserProfile() async {
    final profile = await remoteDataSource.getUserProfile();
    final hasUnread = await localDataSource.hasUnreadNotifications();
    return profile.copyWith(hasUnreadCourierUpdates: hasUnread);
  }

  @override
  Future<void> markNotificationsAsRead() async {
    await remoteDataSource.markNotificationsAsRead();
    await localDataSource.setNotificationsRead(true);
  }
}
