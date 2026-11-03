import '../entities/admin_customer_item.dart';
import '../repositories/admin_customer_repository.dart';

class UpdateCustomerProfileUseCase {
  final AdminCustomerRepository repository;

  const UpdateCustomerProfileUseCase(this.repository);

  Future<AdminCustomerItem> call({
    required int customerId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    double? latitude,
    double? longitude,
    required bool emailVerified,
  }) {
    return repository.updateCustomerProfile(
      customerId: customerId,
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
      idProvinsi: idProvinsi,
      idKabkot: idKabkot,
      idKecamatan: idKecamatan,
      idKelurahan: idKelurahan,
      latitude: latitude,
      longitude: longitude,
      emailVerified: emailVerified,
    );
  }
}

