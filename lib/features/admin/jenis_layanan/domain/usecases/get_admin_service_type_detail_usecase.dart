import '../entities/admin_service_type_detail.dart';
import '../repositories/admin_service_type_repository.dart';

class GetAdminServiceTypeDetailUseCase {
  final AdminServiceTypeRepository repository;

  const GetAdminServiceTypeDetailUseCase(this.repository);

  Future<AdminServiceTypeDetail> call(int serviceId) {
    return repository.getServiceTypeDetail(serviceId);
  }
}

