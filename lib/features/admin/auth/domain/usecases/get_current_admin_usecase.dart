import '../entities/admin_user.dart';
import '../repositories/admin_auth_repository.dart';

class GetCurrentAdminUseCase {
  final AdminAuthRepository repository;

  GetCurrentAdminUseCase(this.repository);

  Future<AdminUser?> execute() {
    return repository.getCurrentAdmin();
  }
}

