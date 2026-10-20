import '../entities/user_account.dart';
import '../repositories/account_repository.dart';

class GetUserAccountUseCase {
  final AccountRepository repository;

  GetUserAccountUseCase(this.repository);

  Future<UserAccount> call() {
    return repository.getUserAccount();
  }
}
