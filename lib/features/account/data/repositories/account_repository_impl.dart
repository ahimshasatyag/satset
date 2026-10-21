import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../shipments/domain/entities/shipment.dart';
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
    UserAccountModel remote;
    try {
      remote = await remoteDataSource.getUserAccount();
    } catch (_) {
      final local = await localDataSource.getSavedAccount();
      if (local != null) return local;
      rethrow;
    }

    // Ambil daftar alamat tersimpan dari local storage
    var savedAddresses = await localDataSource.getSavedAddresses();

    // Jika belum ada alamat tersimpan tapi m_users memiliki alamat lengkap, seed alamat utama
    if (savedAddresses.isEmpty &&
        remote.fullAddress != null &&
        remote.fullAddress!.trim().isNotEmpty) {
      final initialAddress = UserAddressModel(
        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
        label: 'Rumah (Utama)',
        receiverName: remote.name,
        phone: remote.phone,
        fullAddress: remote.fullAddress!,
        latitude: remote.latitude,
        longitude: remote.longitude,
        isPrimary: true,
      );
      savedAddresses = [initialAddress];
      await localDataSource.saveAddresses(savedAddresses);
    }

    final combined = remote.copyWith(
      addresses: savedAddresses,
      savedAddressesCount: savedAddresses.length,
    );

    await localDataSource.saveAccount(UserAccountModel.fromEntity(combined));
    return combined;
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
    try {
      final current = await getUserAccount();
      await updateAccount(current.copyWith(isNotificationsEnabled: enabled));
    } catch (_) {}
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await remoteDataSource.changePassword(newPassword);
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    await remoteDataSource.resendEmailVerification(email);
  }

  @override
  Future<List<UserAddress>> getAddresses() async {
    return await localDataSource.getSavedAddresses();
  }

  @override
  Future<void> saveAddress(UserAddress address) async {
    final currentList = await localDataSource.getSavedAddresses();
    final isFirst = currentList.isEmpty;
    final isPrimary = address.isPrimary || isFirst;

    final updatedModel = UserAddressModel.fromEntity(
      address.copyWith(isPrimary: isPrimary),
    );

    final List<UserAddressModel> result = [];
    bool found = false;

    for (final item in currentList) {
      if (item.id == updatedModel.id) {
        result.add(updatedModel);
        found = true;
      } else {
        result.add(
          isPrimary ? UserAddressModel.fromEntity(item.copyWith(isPrimary: false)) : item,
        );
      }
    }

    if (!found) {
      result.add(updatedModel);
    }

    await localDataSource.saveAddresses(result);

    // Jika alamat ini adalah alamat utama, sinkronkan ke profil m_users
    if (isPrimary) {
      try {
        final currentAccount = await getUserAccount();
        await updateAccount(currentAccount.copyWith(
          fullAddress: updatedModel.fullAddress,
          latitude: updatedModel.latitude,
          longitude: updatedModel.longitude,
          addresses: result,
        ));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final currentList = await localDataSource.getSavedAddresses();
    final wasPrimary = currentList.any((a) => a.id == addressId && a.isPrimary);

    final updatedList = currentList.where((a) => a.id != addressId).toList();

    // Jika alamat yang dihapus sebelumnya adalah alamat utama dan masih ada alamat lain
    if (wasPrimary && updatedList.isNotEmpty) {
      final newPrimary = updatedList.first.copyWith(isPrimary: true);
      updatedList[0] = UserAddressModel.fromEntity(newPrimary);
      try {
        final currentAccount = await getUserAccount();
        await updateAccount(currentAccount.copyWith(
          fullAddress: newPrimary.fullAddress,
          latitude: newPrimary.latitude,
          longitude: newPrimary.longitude,
          addresses: updatedList,
        ));
      } catch (_) {}
    }

    await localDataSource.saveAddresses(updatedList);
  }

  @override
  Future<void> setPrimaryAddress(String addressId) async {
    final currentList = await localDataSource.getSavedAddresses();
    UserAddressModel? newPrimary;

    final updatedList = currentList.map((item) {
      if (item.id == addressId) {
        newPrimary = UserAddressModel.fromEntity(item.copyWith(isPrimary: true));
        return newPrimary!;
      }
      return UserAddressModel.fromEntity(item.copyWith(isPrimary: false));
    }).toList();

    await localDataSource.saveAddresses(updatedList);

    if (newPrimary != null) {
      try {
        final currentAccount = await getUserAccount();
        await updateAccount(currentAccount.copyWith(
          fullAddress: newPrimary!.fullAddress,
          latitude: newPrimary!.latitude,
          longitude: newPrimary!.longitude,
          addresses: updatedList,
        ));
      } catch (_) {}
    }
  }

  @override
  Future<List<Province>> getProvinces() async {
    return await remoteDataSource.getProvinces();
  }

  @override
  Future<List<Regency>> getRegencies(String provinceCode) async {
    return await remoteDataSource.getRegencies(provinceCode);
  }

  @override
  Future<List<District>> getDistricts(String regencyCode) async {
    return await remoteDataSource.getDistricts(regencyCode);
  }

  @override
  Future<List<Village>> getVillages(String districtCode) async {
    return await remoteDataSource.getVillages(districtCode);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearAccount();
  }
}
