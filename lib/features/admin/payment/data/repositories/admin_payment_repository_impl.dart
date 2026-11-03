import '../../domain/entities/admin_payment_detail.dart';
import '../../domain/entities/admin_payment_item.dart';
import '../../domain/repositories/admin_payment_repository.dart';
import '../datasources/admin_payment_remote_datasource.dart';

class AdminPaymentRepositoryImpl implements AdminPaymentRepository {
  final AdminPaymentRemoteDataSource remoteDataSource;

  const AdminPaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminPaymentsPaginatedResult> getPaginatedPayments({
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
    return remoteDataSource.getPaginatedPayments(
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

  @override
  Future<AdminPaymentDetail> getPaymentDetail(int paymentId) {
    return remoteDataSource.getPaymentDetail(paymentId);
  }

  @override
  Future<List<AdminBankReference>> getBankReferences() {
    return remoteDataSource.getBankReferences();
  }

  @override
  Future<String> reconcilePaymentStatus({
    required int paymentId,
    required int shipmentId,
    String? notes,
  }) {
    return remoteDataSource.reconcilePaymentStatus(
      paymentId: paymentId,
      shipmentId: shipmentId,
      notes: notes,
    );
  }

  @override
  Future<void> confirmCodPaymentSettlement({
    required int paymentId,
    required int shipmentId,
    required num verifiedAmount,
    String? settlementReference,
    String? notes,
  }) {
    return remoteDataSource.confirmCodPaymentSettlement(
      paymentId: paymentId,
      shipmentId: shipmentId,
      verifiedAmount: verifiedAmount,
      settlementReference: settlementReference,
      notes: notes,
    );
  }
}

