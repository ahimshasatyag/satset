import '../entities/admin_payment_item.dart';
import '../repositories/admin_payment_repository.dart';

class GetAdminPaymentsUseCase {
  final AdminPaymentRepository repository;

  const GetAdminPaymentsUseCase(this.repository);

  Future<AdminPaymentsPaginatedResult> call({
    String tabCategory = AdminPaymentTab.all,
    String? searchQuery,
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    num? minAmount,
    num? maxAmount,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.getPaginatedPayments(
      tabCategory: tabCategory,
      searchQuery: searchQuery,
      methodFilter: methodFilter,
      statusFilter: statusFilter,
      jenisBankFilter: jenisBankFilter,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }
}

