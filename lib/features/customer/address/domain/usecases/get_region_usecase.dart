import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';
import '../repositories/address_repository.dart';

class GetRegionUseCase {
  final AddressRepository repository;

  const GetRegionUseCase(this.repository);

  Future<List<Province>> getProvinces() => repository.getProvinces();

  Future<List<Regency>> getRegencies(String provinceCode) =>
      repository.getRegencies(provinceCode);

  Future<List<District>> getDistricts(String regencyCode) =>
      repository.getDistricts(regencyCode);

  Future<List<Village>> getVillages(String districtCode) =>
      repository.getVillages(districtCode);
}
