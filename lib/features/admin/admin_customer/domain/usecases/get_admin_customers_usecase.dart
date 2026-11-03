import '../entities/admin_customer_item.dart';
import '../repositories/admin_customer_repository.dart';

class GetAdminCustomersUseCase {
  final AdminCustomerRepository repository;

  const GetAdminCustomersUseCase(this.repository);

  Future<AdminCustomersPaginatedResult> call({
    String? searchQuery,
    String verificationFilter = 'ALL',
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedCustomers(
      searchQuery: searchQuery,
      verificationFilter: verificationFilter,
      startDate: startDate,
      endDate: endDate,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }
}

