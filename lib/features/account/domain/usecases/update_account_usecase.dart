import '../entities/user_account.dart';
import '../repositories/account_repository.dart';

class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<void> call(UserAccount account) {
    return repository.updateAccount(account);
  }
}
