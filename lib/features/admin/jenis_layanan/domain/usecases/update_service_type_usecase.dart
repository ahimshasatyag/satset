import '../entities/admin_service_type_item.dart';
import '../repositories/admin_service_type_repository.dart';

class UpdateServiceTypeUseCase {
  final AdminServiceTypeRepository repository;

  const UpdateServiceTypeUseCase(this.repository);

  Future<AdminServiceTypeItem> call({
    required int serviceId,
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  }) {
    return repository.updateServiceType(
      serviceId: serviceId,
      kode: kode,
      namaLayanan: namaLayanan,
      estimasiHariMin: estimasiHariMin,
      estimasiHariMax: estimasiHariMax,
      deskripsi: deskripsi,
      baseTariffPerKg: baseTariffPerKg,
      isActive: isActive,
    );
  }
}

