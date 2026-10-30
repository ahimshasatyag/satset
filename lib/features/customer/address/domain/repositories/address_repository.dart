import '../entities/address_label.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';
import '../entities/customer_address.dart';

/// Kontrak Repository Domain untuk mengelola data alamat pelanggan:
/// Alamat utama dari tabel `m_users` dan daftar alamat lain dari tabel `m_address`.
abstract class AddressRepository {
  /// Mengambil semua daftar alamat (Alamat Utama `m_users` diletakkan paling atas,
  /// disusul dengan daftar alamat lain dari `m_address`).
  Future<List<CustomerAddress>> getAddresses({int? userId});

  /// Mengambil alamat utama dari profil akun pengguna `m_users`.
  Future<CustomerAddress?> getPrimaryAddress({int? userId});

  /// Menambahkan alamat baru ke tabel `m_address`.
  Future<CustomerAddress> addAddress(CustomerAddress address);

  /// Memperbarui alamat yang sudah ada (baik di `m_address` atau `m_users`).
  Future<CustomerAddress> updateAddress(CustomerAddress address);

  /// Menghapus alamat tambahan dari tabel `m_address`.
  /// Jika alamat utama yang dihapus, maka kolom alamat di `m_users` akan dikosongkan.
  Future<void> deleteAddress(CustomerAddress address);

  /// Menjadikan alamat terpilih sebagai alamat utama pengguna di tabel `m_users`.
  Future<void> setAsPrimaryAddress(CustomerAddress address);

  /// Mengambil daftar master provinsi dari `m_provinsi`
  /// Mengambil daftar master label alamat dari `m_label`
  Future<List<AddressLabel>> getLabels();

  Future<List<Province>> getProvinces();

  /// Mengambil daftar master kabkot dari `m_kabkot` berdasarkan kode provinsi
  Future<List<Regency>> getRegencies(String provinceCode);

  /// Mengambil daftar master kecamatan dari `m_kecamatan` berdasarkan kode kabkot
  Future<List<District>> getDistricts(String regencyCode);

  /// Mengambil daftar master kelurahan dari `m_kelurahan` berdasarkan kode kecamatan
  Future<List<Village>> getVillages(String districtCode);
}
