import '../../domain/entities/customer_address.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/core/error/exceptions.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/customer/shipments/data/models/shipment_model.dart';
import '../models/customer_address_model.dart';

abstract class AddressRemoteDataSource {
  /// Mengambil semua alamat: alamat utama dari `m_users` dan alamat lainnya dari `m_address`
  Future<List<CustomerAddressModel>> getAddresses({int? userId});

  /// Mengambil alamat utama dari tabel `m_users`
  Future<CustomerAddressModel?> getPrimaryAddress({int? userId});

  /// Menambahkan alamat baru ke tabel `m_address`
  Future<CustomerAddressModel> addAddress(CustomerAddressModel address);

  /// Memperbarui alamat yang ada di `m_address` atau `m_users`
  Future<CustomerAddressModel> updateAddress(CustomerAddressModel address);

  /// Menghapus alamat dari `m_address` atau mengosongkan alamat di `m_users`
  Future<void> deleteAddress(CustomerAddressModel address);

  /// Menjadikan suatu alamat sebagai alamat utama pengguna di `m_users`
  Future<void> setAsPrimaryAddress(CustomerAddressModel address);

  /// Mengambil daftar master provinsi dari `m_provinsi`
  /// Mengambil daftar master label alamat dari tabel `m_label`
  Future<List<AddressLabel>> getLabels();

  Future<List<ProvinceModel>> getProvinces();

  /// Mengambil daftar master kabupaten/kota dari `m_kabkot` berdasarkan kode provinsi
  Future<List<RegencyModel>> getRegencies(String provinceCode);

  /// Mengambil daftar master kecamatan dari `m_kecamatan` berdasarkan kode kabupaten/kota
  Future<List<DistrictModel>> getDistricts(String regencyCode);

  /// Mengambil daftar master kelurahan dari `m_kelurahan` berdasarkan kode kecamatan
  Future<List<VillageModel>> getVillages(String districtCode);

  /// Resolve ID pengguna (integer) yang sedang aktif
  Future<int> resolveUserId({int? explicitUserId});
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  AddressRemoteDataSourceImpl({
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
    this.currentUser,
  })  : _customClient = client,
        _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSourceImpl();

  bool get _isSupabaseAvailable {
    if (_customClient != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  @override
  Future<int> resolveUserId({int? explicitUserId}) async {
    if (explicitUserId != null && explicitUserId > 0) return explicitUserId;

    if (currentUser != null && currentUser!.id.isNotEmpty) {
      final parsed = int.tryParse(currentUser!.id);
      if (parsed != null && parsed > 0) return parsed;
    }

    try {
      final savedUser = await _authLocalDataSource?.getUser();
      if (savedUser != null && savedUser.id.isNotEmpty) {
        final parsed = int.tryParse(savedUser.id);
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        final email = (authUser.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          try {
            final res = await _client
                .from(DatabaseConstants.tableUsers)
                .select(DatabaseConstants.colId)
                .eq(DatabaseConstants.colEmail, email)
                .maybeSingle();

            if (res != null && res[DatabaseConstants.colId] != null) {
              final parsed = int.tryParse(res[DatabaseConstants.colId].toString());
              if (parsed != null && parsed > 0) return parsed;
            }
          } catch (_) {}
        }
      }
    }

    return 1; // Default fallback ID untuk customer
  }

  @override
  Future<List<CustomerAddressModel>> getAddresses({int? userId}) async {
    final uid = await resolveUserId(explicitUserId: userId);

    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    try {
      final results = <CustomerAddressModel>[];

      // 1. Ambil data profil pengguna dari tabel `m_users`
      final userRow = await _client
          .from(DatabaseConstants.tableUsers)
          .select()
          .eq(DatabaseConstants.colId, uid)
          .maybeSingle();

      String defaultName = 'Pengguna SatSet';
      String defaultPhone = '';
      CustomerAddressModel? userAddress;
      final bool isUserUtamaInDb = userRow?[UserTableColumns.isUtama] == true;

      if (userRow != null) {
        defaultName = userRow[UserTableColumns.namaLengkap]?.toString() ?? defaultName;
        defaultPhone = userRow[UserTableColumns.noHp]?.toString() ?? '';

        // Resolving region names
        final provCode = userRow[UserTableColumns.idProvinsi]?.toString();
        final kabkotCode = userRow[UserTableColumns.idKabkot]?.toString();
        final kecCode = userRow[UserTableColumns.idKecamatan]?.toString();
        final kelCode = userRow[UserTableColumns.idKelurahan]?.toString();

        final regionNames = await _resolveRegionNames(
          provCode: provCode,
          kabkotCode: kabkotCode,
          kecCode: kecCode,
          kelCode: kelCode,
        );

        userAddress = CustomerAddressModel.fromUsersTable(
          userRow,
          isPrimary: isUserUtamaInDb,
          provinceName: regionNames['province'],
          regencyName: regionNames['regency'],
          districtName: regionNames['district'],
          villageName: regionNames['village'],
          postalCode: regionNames['postalCode'],
        );
      }

      // 2. Ambil daftar alamat lain dari tabel `m_address`
      final addressRows = await _client
          .from(DatabaseConstants.tableAddress)
          .select('*, m_label(id, nm_label)')
          .eq(AddressTableColumns.idUsers, uid)
          .order(AddressTableColumns.createdAt, ascending: false);

      final otherAddresses = <CustomerAddressModel>[];
      bool hasExplicitPrimaryInAddress = false;

      for (final row in addressRows) {
        final provCode = row[AddressTableColumns.idProvinsi]?.toString();
        final kabkotCode = row[AddressTableColumns.idKabkot]?.toString();
        final kelCode = row[AddressTableColumns.idKelurahan]?.toString();
        final isRowUtama = row[AddressTableColumns.isUtama] == true;
        if (isRowUtama) {
          hasExplicitPrimaryInAddress = true;
        }

        final regionNames = await _resolveRegionNames(
          provCode: provCode,
          kabkotCode: kabkotCode,
          kelCode: kelCode,
        );

        otherAddresses.add(
          CustomerAddressModel.fromAddressTable(
            row,
            isPrimary: isRowUtama,
            fallbackName: defaultName,
            fallbackPhone: defaultPhone,
            provinceName: regionNames['province'],
            regencyName: regionNames['regency'],
            districtName: regionNames['district'],
            districtCode: regionNames['districtCode'],
            villageName: regionNames['village'],
          ),
        );
      }

      // 3. Fallback jika di database belum ada satu pun yang is_utama == true
      // (misalnya kolom baru saja ditambahkan dengan DEFAULT FALSE):
      if (!isUserUtamaInDb && !hasExplicitPrimaryInAddress) {
        if (userAddress != null) {
          // Jadikan userAddress sebagai primary fallback
          userAddress = userAddress.copyWith(isPrimary: true);
          // Sekaligus selaraskan m_users.is_utama = true di DB
          _client
              .from(DatabaseConstants.tableUsers)
              .update({UserTableColumns.isUtama: true})
              .eq(DatabaseConstants.colId, uid)
              .ignore();
        } else if (otherAddresses.isNotEmpty) {
          otherAddresses[0] = otherAddresses[0].copyWith(isPrimary: true);
          _client
              .from(DatabaseConstants.tableAddress)
              .update({AddressTableColumns.isUtama: true})
              .eq(AddressTableColumns.id, otherAddresses[0].rawId!)
              .ignore();
        }
      } else if (hasExplicitPrimaryInAddress && isUserUtamaInDb) {
        // Jika ada inkonsistensi kedua tabel bernilai true, prioritaskan m_address dan reset m_users
        if (userAddress != null) {
          userAddress = userAddress.copyWith(isPrimary: false);
          _client
              .from(DatabaseConstants.tableUsers)
              .update({UserTableColumns.isUtama: false})
              .eq(DatabaseConstants.colId, uid)
              .ignore();
        }
      }

      if (userAddress != null) {
        results.add(userAddress);
      }
      results.addAll(otherAddresses);

      return results;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gagal memuat daftar alamat: $e');
    }
  }

  @override
  Future<CustomerAddressModel?> getPrimaryAddress({int? userId}) async {
    final list = await getAddresses(userId: userId);
    try {
      return list.firstWhere((a) => a.isPrimary);
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }

  @override
  Future<CustomerAddressModel> addAddress(CustomerAddressModel address) async {
    final uid = await resolveUserId(explicitUserId: address.userId);

    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    // Jika alamat baru ini ingin dijadikan utama, reset flag is_utama lainnya
    if (address.isPrimary) {
      await _client
          .from(DatabaseConstants.tableAddress)
          .update({AddressTableColumns.isUtama: false})
          .eq(AddressTableColumns.idUsers, uid);

      await _client
          .from(DatabaseConstants.tableUsers)
          .update({UserTableColumns.isUtama: false})
          .eq(DatabaseConstants.colId, uid);
    }

    final payload = address.toAddressTableJson();
    payload[AddressTableColumns.idUsers] = uid;
    payload[AddressTableColumns.isUtama] = address.isPrimary;
    payload[AddressTableColumns.createdAt] = DateTime.now().toIso8601String();

    Map<String, dynamic> inserted;
    try {
      inserted = await _client
          .from(DatabaseConstants.tableAddress)
          .insert(payload)
          .select('*, m_label(id, nm_label)')
          .single();
    } catch (_) {
      inserted = await _client
          .from(DatabaseConstants.tableAddress)
          .insert(payload)
          .select()
          .single();
    }

    final regionNames = await _resolveRegionNames(
      provCode: inserted[AddressTableColumns.idProvinsi]?.toString(),
      kabkotCode: inserted[AddressTableColumns.idKabkot]?.toString(),
      kelCode: inserted[AddressTableColumns.idKelurahan]?.toString(),
    );

    return CustomerAddressModel.fromAddressTable(
      inserted,
      isPrimary: inserted[AddressTableColumns.isUtama] == true,
      fallbackName: address.receiverName,
      fallbackPhone: address.phoneNumber,
      provinceName: regionNames['province'],
      regencyName: regionNames['regency'],
      districtName: regionNames['district'],
      districtCode: regionNames['districtCode'],
      villageName: regionNames['village'],
    );
  }

  @override
  Future<CustomerAddressModel> updateAddress(CustomerAddressModel address) async {
    final uid = await resolveUserId(explicitUserId: address.userId);

    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    if (address.sourceType.isUserPrimary) {
      // Perbarui alamat utama di tabel `m_users`
      final updateData = address.toUsersTableUpdateJson();

      if (address.isPrimary) {
        // Reset alamat di m_address
        await _client
            .from(DatabaseConstants.tableAddress)
            .update({AddressTableColumns.isUtama: false})
            .eq(AddressTableColumns.idUsers, uid);
        updateData[UserTableColumns.isUtama] = true;
      }

      try {
        await _client
            .from(DatabaseConstants.tableUsers)
            .update(updateData)
            .eq(DatabaseConstants.colId, uid);
      } catch (e) {
        if (e is PostgrestException &&
            (e.message.contains('value too long for type character varying') ||
                e.code == '22001' ||
                e.message.contains('fk_users_kelurahan') ||
                e.message.contains('id_kelurahan'))) {
          // Toleransi kolom m_users.id_kelurahan berukuran varchar(12)
          updateData.remove(UserTableColumns.idKelurahan);
          await _client
              .from(DatabaseConstants.tableUsers)
              .update(updateData)
              .eq(DatabaseConstants.colId, uid);
        } else {
          rethrow;
        }
      }

      return address;
    } else {
      // Perbarui alamat lain di tabel `m_address`
      if (address.rawId == null || address.rawId! <= 0) {
        throw Exception('ID alamat m_address tidak valid untuk diperbarui');
      }

      if (address.isPrimary) {
        // Reset alamat m_address lainnya dan profil m_users
        await _client
            .from(DatabaseConstants.tableAddress)
            .update({AddressTableColumns.isUtama: false})
            .eq(AddressTableColumns.idUsers, uid);

        await _client
            .from(DatabaseConstants.tableUsers)
            .update({UserTableColumns.isUtama: false})
            .eq(DatabaseConstants.colId, uid);
      }

      final updateData = address.toAddressTableJson();
      final updated = await _client
          .from(DatabaseConstants.tableAddress)
          .update(updateData)
          .eq(AddressTableColumns.id, address.rawId!)
          .select()
          .single();

      final regionNames = await _resolveRegionNames(
        provCode: updated[AddressTableColumns.idProvinsi]?.toString(),
        kabkotCode: updated[AddressTableColumns.idKabkot]?.toString(),
        kelCode: updated[AddressTableColumns.idKelurahan]?.toString(),
      );

      return CustomerAddressModel.fromAddressTable(
        updated,
        isPrimary: updated[AddressTableColumns.isUtama] == true,
        fallbackName: address.receiverName,
        fallbackPhone: address.phoneNumber,
        provinceName: regionNames['province'],
        regencyName: regionNames['regency'],
        districtName: regionNames['district'],
        districtCode: regionNames['districtCode'],
        villageName: regionNames['village'],
      );
    }
  }

  @override
  Future<void> deleteAddress(CustomerAddressModel address) async {
    final uid = await resolveUserId(explicitUserId: address.userId);

    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    if (address.sourceType.isUserPrimary) {
      // Jika alamat utama profil yang dihapus, kosongkan alamat di m_users
      await _client.from(DatabaseConstants.tableUsers).update({
        UserTableColumns.alamatLengkap: null,
        UserTableColumns.idProvinsi: null,
        UserTableColumns.idKabkot: null,
        UserTableColumns.idKecamatan: null,
        UserTableColumns.idKelurahan: null,
        UserTableColumns.latitude: null,
        UserTableColumns.longitude: null,
        UserTableColumns.isUtama: false,
        UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
      }).eq(DatabaseConstants.colId, uid);

      // Jika ada alamat tersisa di m_address, promosikan alamat pertama menjadi utama
      final remaining = await _client
          .from(DatabaseConstants.tableAddress)
          .select(AddressTableColumns.id)
          .eq(AddressTableColumns.idUsers, uid)
          .order(AddressTableColumns.createdAt, ascending: false)
          .limit(1);

      if ((remaining as List).isNotEmpty) {
        final firstId = remaining.first[AddressTableColumns.id];
        await _client
            .from(DatabaseConstants.tableAddress)
            .update({AddressTableColumns.isUtama: true})
            .eq(AddressTableColumns.id, firstId);
      }
    } else {
      // Hapus dari m_address
      if (address.rawId != null && address.rawId! > 0) {
        await _client
            .from(DatabaseConstants.tableAddress)
            .delete()
            .eq(AddressTableColumns.id, address.rawId!);

        // Jika alamat yang dihapus sebelumnya adalah alamat utama:
        // Otomatis kembalikan status utama ke profil m_users
        if (address.isPrimary) {
          await _client
              .from(DatabaseConstants.tableUsers)
              .update({
                UserTableColumns.isUtama: true,
                UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
              })
              .eq(DatabaseConstants.colId, uid);
        }
      }
    }
  }

  @override
  Future<void> setAsPrimaryAddress(CustomerAddressModel address) async {
    final uid = await resolveUserId(explicitUserId: address.userId);

    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    final isUserTable = address.sourceType.isUserPrimary ||
        address.rawId == null ||
        address.rawId == uid;

    if (isUserTable) {
      // Kasus 1: Pengguna menetapkan Alamat Profil (m_users) sebagai Alamat Utama
      // Reset is_utama di m_address untuk seluruh alamat milik user
      await _client
          .from(DatabaseConstants.tableAddress)
          .update({
            AddressTableColumns.isUtama: false,
            AddressTableColumns.updatedAt: DateTime.now().toIso8601String(),
          })
          .eq(AddressTableColumns.idUsers, uid);

      // Aktifkan is_utama di m_users
      await _client
          .from(DatabaseConstants.tableUsers)
          .update({
            UserTableColumns.isUtama: true,
            UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
          })
          .eq(DatabaseConstants.colId, uid);
    } else {
      // Kasus 2: Pengguna menetapkan salah satu alamat di m_address sebagai Alamat Utama
      // 1. Reset is_utama di m_address untuk seluruh alamat milik user
      await _client
          .from(DatabaseConstants.tableAddress)
          .update({
            AddressTableColumns.isUtama: false,
            AddressTableColumns.updatedAt: DateTime.now().toIso8601String(),
          })
          .eq(AddressTableColumns.idUsers, uid);

      // 2. Aktifkan is_utama untuk baris m_address yang dipilih
      if (address.rawId != null && address.rawId! > 0) {
        await _client
            .from(DatabaseConstants.tableAddress)
            .update({
              AddressTableColumns.isUtama: true,
              AddressTableColumns.updatedAt: DateTime.now().toIso8601String(),
            })
            .eq(AddressTableColumns.id, address.rawId!);
      }

      // 3. Matikan is_utama di profil m_users
      await _client
          .from(DatabaseConstants.tableUsers)
          .update({
            UserTableColumns.isUtama: false,
            UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
          })
          .eq(DatabaseConstants.colId, uid);
    }

    // Sinkronkan ke local user cache jika ada
    try {
      final local = await _authLocalDataSource?.getUser();
      if (local != null) {
        final updatedLocal = local.copyWith(
          alamatLengkap: address.fullAddress,
          latitude: address.latitude,
          longitude: address.longitude,
        );
        await _authLocalDataSource?.saveUser(updatedLocal);
      }
    } catch (_) {}
  }

  // ===========================================================================
  // MASTER WILAYAH
  // ===========================================================================

  @override
  Future<List<AddressLabel>> getLabels() async {
    if (!_isSupabaseAvailable) {
      return <AddressLabel>[];
    }
    try {
      final res = await _client
          .from(DatabaseConstants.tableLabel)
          .select()
          .order('id', ascending: true);
      return (res as List)
          .map((row) => AddressLabel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <AddressLabel>[];
    }
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    try {
      final res = await _client
          .from(DatabaseConstants.tableProvinsi)
          .select()
          .order(ProvinsiTableColumns.namaProvinsi, ascending: true);
      return (res as List).map((e) => ProvinceModel.fromDatabase(e)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat master provinsi: $e');
    }
  }

  @override
  Future<List<RegencyModel>> getRegencies(String provinceCode) async {
    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    try {
      final res = await _client
          .from(DatabaseConstants.tableKabkot)
          .select()
          .eq(KabkotTableColumns.kodeProvinsi, provinceCode)
          .order(KabkotTableColumns.namaKabkot, ascending: true);
      return (res as List).map((e) => RegencyModel.fromDatabase(e)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat master kabkot: $e');
    }
  }

  @override
  Future<List<DistrictModel>> getDistricts(String regencyCode) async {
    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    try {
      final res = await _client
          .from(DatabaseConstants.tableKecamatan)
          .select()
          .eq(KecamatanTableColumns.kodeKabkot, regencyCode)
          .order(KecamatanTableColumns.namaKecamatan, ascending: true);
      return (res as List).map((e) => DistrictModel.fromDatabase(e)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat master kecamatan: $e');
    }
  }

  @override
  Future<List<VillageModel>> getVillages(String districtCode) async {
    if (!_isSupabaseAvailable) {
      throw const ServerException('Koneksi basis data Supabase tidak tersedia');
    }

    try {
      final res = await _client
          .from(DatabaseConstants.tableKelurahan)
          .select()
          .eq(KelurahanTableColumns.kodeKecamatan, districtCode)
          .order(KelurahanTableColumns.namaKelurahan, ascending: true);
      return (res as List).map((e) => VillageModel.fromDatabase(e)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat master kelurahan: $e');
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<Map<String, String?>> _resolveRegionNames({
    String? provCode,
    String? kabkotCode,
    String? kecCode,
    String? kelCode,
  }) async {
    String? provinceName;
    String? regencyName;
    String? districtName;
    String? villageName;
    String? postalCode;
    String? resolvedKecCode = kecCode;

    try {
      if (provCode != null && provCode.isNotEmpty) {
        final res = await _client
            .from(DatabaseConstants.tableProvinsi)
            .select(ProvinsiTableColumns.namaProvinsi)
            .eq(ProvinsiTableColumns.kodeProvinsi, provCode)
            .maybeSingle();
        provinceName = res?[ProvinsiTableColumns.namaProvinsi]?.toString();
      }

      if (kabkotCode != null && kabkotCode.isNotEmpty) {
        final res = await _client
            .from(DatabaseConstants.tableKabkot)
            .select(KabkotTableColumns.namaKabkot)
            .eq(KabkotTableColumns.kodeKabkot, kabkotCode)
            .maybeSingle();
        regencyName = res?[KabkotTableColumns.namaKabkot]?.toString();
      }

      if (kelCode != null && kelCode.isNotEmpty) {
        final res = await _client
            .from(DatabaseConstants.tableKelurahan)
            .select(
              '${KelurahanTableColumns.namaKelurahan}, ${KelurahanTableColumns.kodepos}, ${KelurahanTableColumns.kodeKecamatan}',
            )
            .eq(KelurahanTableColumns.kodeKelurahan, kelCode)
            .maybeSingle();
        villageName = res?[KelurahanTableColumns.namaKelurahan]?.toString();
        postalCode = res?[KelurahanTableColumns.kodepos]?.toString();
        resolvedKecCode ??=
            res?[KelurahanTableColumns.kodeKecamatan]?.toString();
      }

      // Jika kecCode belum ada tapi kelCode berformat standar dengan titik, ambil prefix
      if ((resolvedKecCode == null || resolvedKecCode.isEmpty) &&
          kelCode != null &&
          kelCode.contains('.')) {
        final lastDot = kelCode.lastIndexOf('.');
        if (lastDot > 0) {
          resolvedKecCode = kelCode.substring(0, lastDot);
        }
      }

      if (resolvedKecCode != null && resolvedKecCode.isNotEmpty) {
        final res = await _client
            .from(DatabaseConstants.tableKecamatan)
            .select(KecamatanTableColumns.namaKecamatan)
            .eq(KecamatanTableColumns.kodeKecamatan, resolvedKecCode)
            .maybeSingle();
        districtName = res?[KecamatanTableColumns.namaKecamatan]?.toString();
      }
    } catch (_) {}

    return {
      'province': provinceName,
      'regency': regencyName,
      'district': districtName,
      'districtCode': resolvedKecCode,
      'village': villageName,
      'postalCode': postalCode,
    };
  }
}
