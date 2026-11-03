import '../entities/admin_delivery_item.dart';
import '../repositories/admin_delivery_repository.dart';

class GetAdminDeliveriesUseCase {
  final AdminDeliveryRepository repository;

  const GetAdminDeliveriesUseCase(this.repository);

  Future<AdminDeliveriesPaginatedResult> call({
    String tabCategory = AdminDeliveryTab.all,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedDeliveries(
      tabCategory: tabCategory,
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      paymentMethodFilter: paymentMethodFilter,
      paymentStatusFilter: paymentStatusFilter,
      serviceFilter: serviceFilter,
      courierFilter: courierFilter,
      startDate: startDate,
      endDate: endDate,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }
}

