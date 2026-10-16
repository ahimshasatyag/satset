import '../repositories/auth_repository.dart';

/// Use case untuk keluar dari akun (logout)
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() async {
    await repository.logout();
  }
}
