import '../entities/admin_courier_item.dart';
import '../repositories/admin_courier_repository.dart';

class GetAdminCouriersUseCase {
  final AdminCourierRepository repository;

  const GetAdminCouriersUseCase(this.repository);

  Future<AdminCouriersPaginatedResult> call({
    String? searchQuery,
    String accountStatusFilter = 'ALL',
    String activityStatusFilter = 'ALL',
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedCouriers(
      searchQuery: searchQuery,
      accountStatusFilter: accountStatusFilter,
      activityStatusFilter: activityStatusFilter,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }
}

