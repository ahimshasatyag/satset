import '../entities/user_account.dart';

abstract class AccountRepository {
  /// Mengambil data profil dan akun pengguna yang aktif
  Future<UserAccount> getUserAccount();

  /// Memperbarui profil akun pengguna
  Future<void> updateAccount(UserAccount account);

  /// Mengubah preferensi status notifikasi
  Future<void> setNotificationsEnabled(bool enabled);

  /// Melakukan logout dan pembersihan sesi pengguna
  Future<void> logout();
}
