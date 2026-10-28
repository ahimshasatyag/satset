import '../../domain/entities/shipment.dart';
import '../../domain/repositories/shipment_repository.dart';
import '../datasources/shipment_local_datasource.dart';
import '../datasources/shipment_remote_datasource.dart';

class ShipmentRepositoryImpl implements ShipmentRepository {
  final ShipmentRemoteDataSource remoteDataSource;
  final ShipmentLocalDataSource localDataSource;

  ShipmentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<OrderShipment> createShipmentOrder(Map<String, dynamic> data) async {
    final shipment = await remoteDataSource.createShipmentOrder(data);
    await localDataSource.clearShipmentDraft();
    return shipment;
  }

  @override
  Future<OrderShipment> createShipment(Map<String, dynamic> data) {
    return createShipmentOrder(data);
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

  @override
  Future<List<BankAccount>> getBanks() {
    return remoteDataSource.getBanks();
  }

  @override
  Future<void> updateUserMainAddress({
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? namaLengkap,
    String? noHp,
  }) {
    return remoteDataSource.updateUserMainAddress(
      idProvinsi: idProvinsi,
      idKabkot: idKabkot,
      idKecamatan: idKecamatan,
      idKelurahan: idKelurahan,
      alamatLengkap: alamatLengkap,
      latitude: latitude,
      longitude: longitude,
      namaLengkap: namaLengkap,
      noHp: noHp,
    );
  }
}
