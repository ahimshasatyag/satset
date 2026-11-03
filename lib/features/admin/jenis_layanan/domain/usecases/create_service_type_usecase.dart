import '../entities/admin_service_type_item.dart';
import '../repositories/admin_service_type_repository.dart';

class CreateServiceTypeUseCase {
  final AdminServiceTypeRepository repository;

  const CreateServiceTypeUseCase(this.repository);

  Future<AdminServiceTypeItem> call({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    bool isActive = true,
  }) {
    return repository.createServiceType(
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

