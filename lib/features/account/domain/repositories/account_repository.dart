import '../entities/user_account.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';

abstract class AccountRepository {
  /// Mengambil data profil dan akun pengguna yang aktif
  Future<UserAccount> getUserAccount();

  /// Memperbarui profil akun pengguna (nama, no_hp, alamat, dll)
  Future<void> updateAccount(UserAccount account);

  /// Mengubah preferensi status notifikasi
  Future<void> setNotificationsEnabled(bool enabled);

  /// Mengubah kata sandi akun pelanggan via Supabase Auth
  Future<void> changePassword(String newPassword);

  /// Mengirim ulang link / kode verifikasi email akun
  Future<void> resendEmailVerification(String email);

  /// Mengambil daftar alamat tersimpan milik pelanggan
  Future<List<UserAddress>> getAddresses();

  /// Menyimpan atau memperbarui alamat pengiriman
  Future<void> saveAddress(UserAddress address);

  /// Menghapus alamat tersimpan pelanggan
  Future<void> deleteAddress(String addressId);

  /// Menetapkan alamat tertentu sebagai alamat utama
  Future<void> setPrimaryAddress(String addressId);

  /// Mengambil daftar master provinsi untuk form alamat
  Future<List<Province>> getProvinces();

  /// Mengambil daftar master kabupaten/kota untuk form alamat
  Future<List<Regency>> getRegencies(String provinceCode);

  /// Mengambil daftar master kecamatan untuk form alamat
  Future<List<District>> getDistricts(String regencyCode);

  /// Mengambil daftar master kelurahan untuk form alamat
  Future<List<Village>> getVillages(String districtCode);

  /// Melakukan logout dan pembersihan sesi pengguna
  Future<void> logout();
}
