import '../repositories/account_repository.dart';

class LogoutAccountUseCase {
  final AccountRepository repository;

  LogoutAccountUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}
