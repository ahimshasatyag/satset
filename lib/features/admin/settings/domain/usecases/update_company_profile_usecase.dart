import '../entities/company_profile.dart';
import '../repositories/admin_settings_repository.dart';

class UpdateCompanyProfileUseCase {
  final AdminSettingsRepository repository;

  const UpdateCompanyProfileUseCase(this.repository);

  Future<CompanyProfile> call(CompanyProfile profile) {
    if (profile.companyName.trim().isEmpty) {
      throw Exception('Nama perusahaan tidak boleh kosong.');
    }
    if (profile.contactEmail.trim().isEmpty ||
        !profile.contactEmail.contains('@')) {
      throw Exception('Alamat email kontak perusahaan tidak valid.');
    }
    if (profile.contactPhone.trim().isEmpty) {
      throw Exception('Nomor kontak perusahaan tidak boleh kosong.');
    }

    return repository.updateCompanyProfile(profile);
  }
}

