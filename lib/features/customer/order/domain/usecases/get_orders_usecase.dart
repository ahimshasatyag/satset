import '../entities/order_shipment.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepository repository;

  GetOrdersUseCase(this.repository);

  Future<List<OrderShipment>> call({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  }) {
    return repository.getOrders(direction: direction, filter: filter);
  }
}
