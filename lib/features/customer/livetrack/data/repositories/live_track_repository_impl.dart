import '../../domain/entities/live_track_shipment.dart';
import '../../domain/repositories/live_track_repository.dart';
import '../datasources/live_track_local_datasource.dart';
import '../datasources/live_track_remote_datasource.dart';

class LiveTrackRepositoryImpl implements LiveTrackRepository {
  final LiveTrackRemoteDataSource remoteDataSource;
  final LiveTrackLocalDataSource localDataSource;

  LiveTrackRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<List<LiveTrackShipment>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
    String? specificResi,
  }) {
    return remoteDataSource.getLiveTrackingOrdersStream(
      direction: direction,
      specificResi: specificResi,
    );
  }

  @override
  Future<List<LiveTrackShipment>> getActiveTrackingOrders({
    required OrderDirection direction,
    String? specificResi,
  }) {
    return remoteDataSource.getActiveTrackingOrders(
      direction: direction,
      specificResi: specificResi,
    );
  }

  @override
  Future<LiveTrackShipment?> getShipmentByResi({
    required String resi,
  }) {
    return remoteDataSource.getShipmentByResi(resi: resi);
  }
}
