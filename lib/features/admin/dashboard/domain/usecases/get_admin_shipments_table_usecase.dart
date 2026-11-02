import '../entities/admin_shipment_table_item.dart';
import '../repositories/admin_dashboard_repository.dart';

class GetAdminShipmentsTableUseCase {
  final AdminDashboardRepository repository;

  GetAdminShipmentsTableUseCase(this.repository);

  Future<AdminShipmentsPaginatedResult> execute({
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    int? courierIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedShipments(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      serviceFilter: serviceFilter,
      courierIdFilter: courierIdFilter,
      startDate: startDate,
      endDate: endDate,
      page: page,
      pageSize: pageSize,
    );
  }
}

