import '../repositories/order_repository.dart';

class GetActiveOrdersCountStreamUseCase {
  final OrderRepository repository;

  GetActiveOrdersCountStreamUseCase(this.repository);

  Stream<int> call() {
    return repository.getActiveOrdersCountStream();
  }
}
