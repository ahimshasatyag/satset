import '../../domain/entities/order_shipment.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<int> getActiveOrdersCountStream() {
    return remoteDataSource.getActiveOrdersCountStream();
  }

  @override
  Future<List<OrderShipment>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  }) async {
    final remoteOrders = await remoteDataSource.getOrders(
      direction: direction,
      filter: filter,
    );
    await localDataSource.cacheOrders(remoteOrders);
    return remoteOrders;
  }

  @override
  Future<OrderShipment> createShipmentOrder(Map<String, dynamic> data) async {
    final created = await remoteDataSource.createShipmentOrder(data);
    // Simpan alamat pengirim terakhir agar nyaman saat pemesanan berikutnya
    await localDataSource.saveLastSenderAddress({
      'pengirim_nama': created.senderName,
      'pengirim_no_hp': created.senderPhone,
      'pengirim_alamat': created.senderAddress,
      'pengirim_kota': created.originCity,
      'pengirim_kode_pos': created.senderPostalCode,
      'pengirim_latitude': created.senderLatitude,
      'pengirim_longitude': created.senderLongitude,
    });
    return created;
  }

  @override
  Future<List<OrderServiceType>> getServiceTypes() {
    return remoteDataSource.getServiceTypes();
  }

  @override
  Future<List<Province>> getProvinces() {
    return remoteDataSource.getProvinces();
  }

  @override
  Future<List<Regency>> getRegencies(String provinceCode) {
    return remoteDataSource.getRegencies(provinceCode);
  }

  @override
  Future<List<District>> getDistricts(String regencyCode) {
    return remoteDataSource.getDistricts(regencyCode);
  }

  @override
  Future<List<Village>> getVillages(String districtCode) {
    return remoteDataSource.getVillages(districtCode);
  }

  @override
  Future<ShipmentPayment?> verifyPaymentStatus(String shipmentId) {
    return remoteDataSource.verifyPaymentStatus(shipmentId);
  }

  @override
  Stream<ShipmentPayment?> streamPaymentStatus(String shipmentId) {
    return remoteDataSource.streamPaymentStatus(shipmentId);
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserProfile() {
    return remoteDataSource.getCurrentUserProfile();
  }
}
