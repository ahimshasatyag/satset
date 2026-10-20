import '../models/user_account_model.dart';

abstract class AccountRemoteDataSource {
  Future<UserAccountModel> getUserAccount();
  Future<void> updateAccount(UserAccountModel account);
  Future<void> logout();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  UserAccountModel _cachedAccount = const UserAccountModel(
    id: 'usr-01',
    name: 'Satria Perkasa',
    email: 'satria@satset.id',
    phone: '+62 812-3456-7890',
    membershipTier: 'SatSet Priority Member',
    satsetPayBalance: 450000,
    savedAddressesCount: 3,
    insuranceClaimsCount: 0,
    isNotificationsEnabled: true,
  );

  @override
  Future<UserAccountModel> getUserAccount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _cachedAccount;
  }

  @override
  Future<void> updateAccount(UserAccountModel account) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cachedAccount = account;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
