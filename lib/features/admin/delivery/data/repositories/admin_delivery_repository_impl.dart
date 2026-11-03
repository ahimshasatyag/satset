import '../../domain/entities/admin_assignable_courier.dart';
import '../../domain/entities/admin_delivery_detail.dart';
import '../../domain/entities/admin_delivery_item.dart';
import '../../domain/repositories/admin_delivery_repository.dart';
import '../datasources/admin_delivery_remote_datasource.dart';

class AdminDeliveryRepositoryImpl implements AdminDeliveryRepository {
  final AdminDeliveryRemoteDataSource remoteDataSource;

  const AdminDeliveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminDeliveriesPaginatedResult> getPaginatedDeliveries({
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
    return remoteDataSource.getPaginatedDeliveries(
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

  @override
  Future<AdminDeliveryDetail> getDeliveryDetail(int shipmentId) {
    return remoteDataSource.getDeliveryDetail(shipmentId);
  }

  @override
  Future<List<AdminAssignableCourier>> getAssignableCouriers() {
    return remoteDataSource.getAssignableCouriers();
  }

  @override
  Future<void> confirmShipmentOrder({
    required int shipmentId,
    String? notes,
  }) {
    return remoteDataSource.confirmShipmentOrder(
      shipmentId: shipmentId,
      notes: notes,
    );
  }

  @override
  Future<void> assignCourierToShipment({
    required int shipmentId,
    required int courierId,
    String? notes,
  }) {
    return remoteDataSource.assignCourierToShipment(
      shipmentId: shipmentId,
      courierId: courierId,
      notes: notes,
    );
  }

  @override
  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String targetStatusCode,
    String? lokasiNama,
    String? notes,
  }) {
    return remoteDataSource.updateShipmentStatus(
      shipmentId: shipmentId,
      targetStatusCode: targetStatusCode,
      lokasiNama: lokasiNama,
      notes: notes,
    );
  }

  @override
  Future<void> handleFailedDelivery({
    required int shipmentId,
    required String resolutionAction,
    int? reassignCourierId,
    String? notes,
  }) {
    return remoteDataSource.handleFailedDelivery(
      shipmentId: shipmentId,
      resolutionAction: resolutionAction,
      reassignCourierId: reassignCourierId,
      notes: notes,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() {
    return remoteDataSource.getStatusReferences();
  }

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() {
    return remoteDataSource.getServiceTypeReferences();
  }
}

