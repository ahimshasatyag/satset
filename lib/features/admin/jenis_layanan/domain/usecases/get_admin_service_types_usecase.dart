import '../entities/admin_service_type_item.dart';
import '../repositories/admin_service_type_repository.dart';

class GetAdminServiceTypesUseCase {
  final AdminServiceTypeRepository repository;

  const GetAdminServiceTypesUseCase(this.repository);

  Future<AdminServiceTypesPaginatedResult> call({
    String? searchQuery,
    String statusFilter = 'ALL',
    String sortColumn = 'id',
    bool sortAscending = true,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedServiceTypes(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }
}

