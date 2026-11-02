import '../repositories/admin_auth_repository.dart';

class AdminLogoutUseCase {
  final AdminAuthRepository repository;

  AdminLogoutUseCase(this.repository);

  Future<void> execute() {
    return repository.logout();
  }
}

