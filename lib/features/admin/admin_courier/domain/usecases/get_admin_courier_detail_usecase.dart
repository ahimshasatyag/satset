import '../entities/admin_courier_detail.dart';
import '../repositories/admin_courier_repository.dart';

class GetAdminCourierDetailUseCase {
  final AdminCourierRepository repository;

  const GetAdminCourierDetailUseCase(this.repository);

  Future<AdminCourierDetail> call(int courierId) {
    return repository.getCourierDetail(courierId);
  }
}

