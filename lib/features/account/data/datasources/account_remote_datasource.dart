import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../app/constants/database_constants.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/utils/password_hasher.dart';
import 'package:satset/features/customer/shipments/data/models/shipment_model.dart';
import '../models/user_account_model.dart';

abstract class AccountRemoteDataSource {
  Future<UserAccountModel> getUserAccount();
  Future<void> updateAccount(UserAccountModel account);
  Future<void> changePassword(String newPassword);
  Future<void> resendEmailVerification(String email);
  Future<List<ProvinceModel>> getProvinces();
  Future<List<RegencyModel>> getRegencies(String provinceCode);
  Future<List<DistrictModel>> getDistricts(String regencyCode);
  Future<List<VillageModel>> getVillages(String districtCode);
  Future<void> logout();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;

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

  AccountRemoteDataSourceImpl({
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
  })  : _customClient = client,
        _authLocalDataSource = authLocalDataSource;

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
  Future<UserAccountModel> getUserAccount() async {
    if (!_isSupabaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedAccount;
    }

    try {
      final authUser = _client.auth.currentUser;
      String? targetEmail = authUser?.email;

      if (targetEmail == null || targetEmail.isEmpty) {
        final localUser = await (_authLocalDataSource ?? AuthLocalDataSourceImpl()).getUser();
        targetEmail = localUser?.email;
      }

      if (targetEmail == null || targetEmail.isEmpty) {
        return _cachedAccount;
      }

      final cleanEmail = targetEmail.trim().toLowerCase();

      // Query tabel m_users
      final userRow = await _client
          .from(DatabaseConstants.tableUsers)
          .select()
          .eq(UserTableColumns.email, cleanEmail)
          .maybeSingle();

      if (userRow == null) {
        return _cachedAccount;
      }

      final isEmailVerified =
          authUser?.emailConfirmedAt != null || authUser?.confirmedAt != null;

      // Hitung riwayat pengiriman t_shipments milik pelanggan
      int shipmentCount = 0;
      try {
        final userId = userRow[UserTableColumns.id]?.toString();
        final userPhone = userRow[UserTableColumns.noHp]?.toString();

        if (userId != null && userId.isNotEmpty) {
          final res = await _client
              .from(DatabaseConstants.tableShipments)
              .select(ShipmentTableColumns.id)
              .or('${ShipmentTableColumns.customerId}.eq.$userId,${ShipmentTableColumns.pengirimNoHp}.eq.$userPhone');
          shipmentCount = (res as List).length;
        }
      } catch (_) {
        shipmentCount = 0;
      }

      final accountModel = UserAccountModel.fromDatabase(
        userRow,
        isEmailVerified: isEmailVerified,
        shipmentCount: shipmentCount,
      );

      _cachedAccount = accountModel;
      return accountModel;
    } catch (_) {
      return _cachedAccount;
    }
  }

  @override
  Future<void> updateAccount(UserAccountModel account) async {
    if (!_isSupabaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 150));
      _cachedAccount = account;
      return;
    }

    try {
      final updateData = <String, dynamic>{
        UserTableColumns.namaLengkap: account.name,
        UserTableColumns.noHp: account.phone,
        UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
      };

      if (account.fullAddress != null && account.fullAddress!.isNotEmpty) {
        updateData[UserTableColumns.alamatLengkap] = account.fullAddress;
      }
      if (account.latitude != null) {
        updateData[UserTableColumns.latitude] = account.latitude;
      }
      if (account.longitude != null) {
        updateData[UserTableColumns.longitude] = account.longitude;
      }

      if (account.id.isNotEmpty && account.id != 'usr-01') {
        await _client
            .from(DatabaseConstants.tableUsers)
            .update(updateData)
            .eq(UserTableColumns.id, account.id);
      } else {
        await _client
            .from(DatabaseConstants.tableUsers)
            .update(updateData)
            .eq(UserTableColumns.email, account.email.trim().toLowerCase());
      }

      _cachedAccount = account;
    } catch (e) {
      // Re-throw if critical error
      _cachedAccount = account;
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    if (!_isSupabaseAvailable) return;

    try {
      // 1. Perbarui kata sandi melalui Supabase Auth
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (_) {}

    try {
      // 2. Sinkronkan hash kata sandi pada m_users jika kolom tersedia
      final authUser = _client.auth.currentUser;
      final email = authUser?.email ?? _cachedAccount.email;
      if (email.isNotEmpty) {
        final hashedPassword = PasswordHasher.hash(newPassword);
        await _client.from(DatabaseConstants.tableUsers).update({
          UserTableColumns.password: hashedPassword,
          UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
        }).eq(UserTableColumns.email, email.trim().toLowerCase());
      }
    } catch (_) {}
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    if (!_isSupabaseAvailable) return;
    final cleanEmail = email.trim().toLowerCase();
    await _client.auth.resend(
      type: OtpType.signup,
      email: cleanEmail,
    );
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    if (!_isSupabaseAvailable) {
      return const [
        ProvinceModel(code: '31', name: 'DKI JAKARTA'),
        ProvinceModel(code: '32', name: 'JAWA BARAT'),
        ProvinceModel(code: '33', name: 'JAWA TENGAH'),
        ProvinceModel(code: '35', name: 'JAWA TIMUR'),
        ProvinceModel(code: '36', name: 'BANTEN'),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableProvinsi)
          .select()
          .order(ProvinsiTableColumns.namaProvinsi, ascending: true);

      return (rows as List)
          .map<ProvinceModel>((r) => ProvinceModel.fromDatabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [
        ProvinceModel(code: '31', name: 'DKI JAKARTA'),
        ProvinceModel(code: '32', name: 'JAWA BARAT'),
      ];
    }
  }

  @override
  Future<List<RegencyModel>> getRegencies(String provinceCode) async {
    if (!_isSupabaseAvailable) {
      return [
        RegencyModel(code: '$provinceCode.01', provinceCode: provinceCode, name: 'Kota Administrasi Pusat', type: 'KOTA'),
        RegencyModel(code: '$provinceCode.02', provinceCode: provinceCode, name: 'Kota Administrasi Selatan', type: 'KOTA'),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKabkot)
          .select()
          .eq(KabkotTableColumns.kodeProvinsi, provinceCode)
          .order(KabkotTableColumns.namaKabkot, ascending: true);

      return (rows as List)
          .map<RegencyModel>((r) => RegencyModel.fromDatabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DistrictModel>> getDistricts(String regencyCode) async {
    if (!_isSupabaseAvailable) {
      return [
        DistrictModel(code: '$regencyCode.01', regencyCode: regencyCode, name: 'Kecamatan Gambir'),
        DistrictModel(code: '$regencyCode.02', regencyCode: regencyCode, name: 'Kecamatan Kebayoran Baru'),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKecamatan)
          .select()
          .eq(KecamatanTableColumns.kodeKabkot, regencyCode)
          .order(KecamatanTableColumns.namaKecamatan, ascending: true);

      return (rows as List)
          .map<DistrictModel>((r) => DistrictModel.fromDatabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VillageModel>> getVillages(String districtCode) async {
    if (!_isSupabaseAvailable) {
      return [
        VillageModel(code: '$districtCode.01', districtCode: districtCode, name: 'Kelurahan Senayan', postalCode: '10270'),
        VillageModel(code: '$districtCode.02', districtCode: districtCode, name: 'Kelurahan Kebayoran', postalCode: '12110'),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKelurahan)
          .select()
          .eq(KelurahanTableColumns.kodeKecamatan, districtCode)
          .order(KelurahanTableColumns.namaKelurahan, ascending: true);

      return (rows as List)
          .map<VillageModel>((r) => VillageModel.fromDatabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> logout() async {
    if (_isSupabaseAvailable) {
      try {
        await _client.auth.signOut();
      } catch (_) {}
    }
    try {
      await (_authLocalDataSource ?? AuthLocalDataSourceImpl()).deleteUser();
    } catch (_) {}
  }
}
