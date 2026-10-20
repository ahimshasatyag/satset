import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_datasource.dart';
import '../datasources/account_remote_datasource.dart';
import '../models/user_account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final AccountLocalDataSource localDataSource;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserAccount> getUserAccount() async {
    final local = await localDataSource.getSavedAccount();
    if (local != null) {
      return local;
    }
    final remote = await remoteDataSource.getUserAccount();
    await localDataSource.saveAccount(remote);
    return remote;
  }

  @override
  Future<void> updateAccount(UserAccount account) async {
    final model = UserAccountModel.fromEntity(account);
    await remoteDataSource.updateAccount(model);
    await localDataSource.saveAccount(model);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await localDataSource.setNotificationsEnabled(enabled);
    final current = await getUserAccount();
    await updateAccount(current.copyWith(isNotificationsEnabled: enabled));
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearAccount();
  }
}
