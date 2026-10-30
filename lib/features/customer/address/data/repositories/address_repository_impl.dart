import 'package:satset/core/error/exceptions.dart';
import 'package:satset/core/error/failures.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';
import '../models/customer_address_model.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  const AddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CustomerAddress>> getAddresses({int? userId}) async {
    try {
      final list = await remoteDataSource.getAddresses(userId: userId);
      return list;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal memuat daftar alamat: ${e.toString()}');
    }
  }

  @override
  Future<CustomerAddress?> getPrimaryAddress({int? userId}) async {
    try {
      return await remoteDataSource.getPrimaryAddress(userId: userId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal memuat alamat utama: ${e.toString()}');
    }
  }

  @override
  Future<CustomerAddress> addAddress(CustomerAddress address) async {
    try {
      final model = CustomerAddressModel.fromEntity(address);

      final result = await remoteDataSource.addAddress(model);

      // Jika pengguna memilih "Jadikan Alamat Utama" pada form tambah
      if (address.isPrimary) {
        await remoteDataSource.setAsPrimaryAddress(result);
      }

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal menambahkan alamat baru: ${e.toString()}');
    }
  }

  @override
  Future<CustomerAddress> updateAddress(CustomerAddress address) async {
    try {
      final model = CustomerAddressModel.fromEntity(address);

      final result = await remoteDataSource.updateAddress(model);

      if (address.isPrimary) {
        await remoteDataSource.setAsPrimaryAddress(result);
      }

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal memperbarui alamat: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAddress(CustomerAddress address) async {
    try {
      final model = CustomerAddressModel.fromEntity(address);
      await remoteDataSource.deleteAddress(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal menghapus alamat: ${e.toString()}');
    }
  }

  @override
  Future<void> setAsPrimaryAddress(CustomerAddress address) async {
    try {
      final model = CustomerAddressModel.fromEntity(address).copyWith(isPrimary: true);
      await remoteDataSource.setAsPrimaryAddress(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal mengubah alamat utama: ${e.toString()}');
    }
  }

  @override
  Future<List<AddressLabel>> getLabels() {
    return remoteDataSource.getLabels();
  }

  @override
  Future<List<Province>> getProvinces() async {
    try {
      return await remoteDataSource.getProvinces();
    } catch (e) {
      throw ServerFailure('Gagal memuat master provinsi: ${e.toString()}');
    }
  }

  @override
  Future<List<Regency>> getRegencies(String provinceCode) async {
    try {
      return await remoteDataSource.getRegencies(provinceCode);
    } catch (e) {
      throw ServerFailure('Gagal memuat master kabkot: ${e.toString()}');
    }
  }

  @override
  Future<List<District>> getDistricts(String regencyCode) async {
    try {
      return await remoteDataSource.getDistricts(regencyCode);
    } catch (e) {
      throw ServerFailure('Gagal memuat master kecamatan: ${e.toString()}');
    }
  }

  @override
  Future<List<Village>> getVillages(String districtCode) async {
    try {
      return await remoteDataSource.getVillages(districtCode);
    } catch (e) {
      throw ServerFailure('Gagal memuat master kelurahan: ${e.toString()}');
    }
  }
}
