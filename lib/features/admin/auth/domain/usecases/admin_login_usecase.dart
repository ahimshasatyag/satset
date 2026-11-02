import '../entities/admin_user.dart';
import '../repositories/admin_auth_repository.dart';

class AdminLoginUseCase {
  final AdminAuthRepository repository;

  AdminLoginUseCase(this.repository);

  Future<AdminUser> execute({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}

