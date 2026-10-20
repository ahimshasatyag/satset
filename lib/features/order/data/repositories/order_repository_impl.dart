import '../../domain/entities/order_shipment.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<int> getActiveOrdersCountStream() {
    return remoteDataSource.getActiveOrdersCountStream();
  }

  @override
  Future<List<OrderShipment>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  }) async {
    final remoteOrders = await remoteDataSource.getOrders(
      direction: direction,
      filter: filter,
    );
    await localDataSource.cacheOrders(remoteOrders);
    return remoteOrders;
  }

  @override
  Future<void> createShipmentOrder(Map<String, dynamic> data) {
    return remoteDataSource.createShipmentOrder(data);
  }
}
