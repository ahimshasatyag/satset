import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../app/config/supabase_config.dart';
import '../../../../app/constants/database_constants.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/utils/password_hasher.dart';
import '../../../auth/domain/entities/user.dart';

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
  final User? currentUser;

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
    this.currentUser,
  }) : _customClient = client,
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
    // 1. Ambil data lokal user kurir atau pelanggan terlebih dahulu
    final localUser =
        currentUser ??
        await (_authLocalDataSource ?? AuthLocalDataSourceImpl()).getUser();

    final authUser = _isSupabaseAvailable ? _client.auth.currentUser : null;
    String? targetEmail = localUser?.email;
    if (targetEmail == null || targetEmail.isEmpty) {
      targetEmail = authUser?.email;
    }

    String? targetId = localUser?.id;
    if (targetId == null || targetId.isEmpty) {
      targetId = authUser?.id;
    }

    final isCourierHint = localUser?.isCourier == true;

    // Jika Supabase tidak tersedia (offline atau environment testing)
    if (!_isSupabaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (localUser != null && localUser.isNotEmpty) {
        final offlineAccount = UserAccountModel(
          id: localUser.id,
          name: localUser.name.isNotEmpty
              ? localUser.name
              : (isCourierHint ? 'Kurir SatSet' : 'Pelanggan SatSet'),
          email: localUser.email,
          phone: localUser.phone,
          fullAddress: localUser.alamatLengkap,
          latitude: localUser.latitude,
          longitude: localUser.longitude,
          membershipTier: isCourierHint
              ? 'Mitra Kurir SatSet'
              : 'SatSet Priority Member',
          isCourier: isCourierHint,
          satsetPayBalance: isCourierHint ? 0 : 450000,
          savedAddressesCount: localUser.alamatLengkap != null ? 1 : 0,
        );
        _cachedAccount = offlineAccount;
        return offlineAccount;
      }
      return _cachedAccount;
    }

    try {
      final cleanEmail = (targetEmail ?? '').trim().toLowerCase();
      final isEmailVerified =
          authUser?.emailConfirmedAt != null || authUser?.confirmedAt != null;

      Map<String, dynamic>? employeeRow;
      Map<String, dynamic>? userRow;

      // 2. Jika akun terindikasi sebagai kurir, prioritaskan query tabel m_employee
      if (isCourierHint) {
        try {
          if (cleanEmail.isNotEmpty) {
            employeeRow = await _client
                .from(DatabaseConstants.tableEmployee)
                .select()
                .eq(EmployeeTableColumns.email, cleanEmail)
                .maybeSingle();
          }
          if (employeeRow == null && targetId != null && targetId.isNotEmpty) {
            employeeRow = await _client
                .from(DatabaseConstants.tableEmployee)
                .select()
                .or(
                  '${DatabaseConstants.colId}.eq.$targetId,user_id.eq.$targetId',
                )
                .maybeSingle();
          }
        } catch (_) {}
      }

      // 3. Jika bukan kurir atau tidak ditemukan di m_employee, query tabel m_users
      if (employeeRow == null && cleanEmail.isNotEmpty) {
        try {
          userRow = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.email, cleanEmail)
              .maybeSingle();
        } catch (_) {}
      }

      // 4. Jika masih belum ditemukan di m_users, coba query tabel m_employee
      if (userRow == null && employeeRow == null) {
        try {
          if (cleanEmail.isNotEmpty) {
            employeeRow = await _client
                .from(DatabaseConstants.tableEmployee)
                .select()
                .eq(EmployeeTableColumns.email, cleanEmail)
                .maybeSingle();
          }
          if (employeeRow == null && targetId != null && targetId.isNotEmpty) {
            employeeRow = await _client
                .from(DatabaseConstants.tableEmployee)
                .select()
                .or(
                  '${DatabaseConstants.colId}.eq.$targetId,user_id.eq.$targetId',
                )
                .maybeSingle();
          }
        } catch (_) {}
      }

      // A. Jika profil ditemukan di m_employee (AKUN KURIR)
      if (employeeRow != null) {
        final empId =
            employeeRow[DatabaseConstants.colId]?.toString() ?? targetId ?? '';
        final empCode =
            employeeRow[EmployeeTableColumns.employeeCode]?.toString() ??
            employeeRow['employee_code']?.toString() ??
            '001';
        final empName =
            employeeRow[EmployeeTableColumns.namaLengkap] as String? ??
            employeeRow[EmployeeTableColumns.nama] as String? ??
            employeeRow['nama_lengkap'] as String? ??
            employeeRow['nama'] as String? ??
            localUser?.name ??
            'Kurir SatSet';
        final empPhone =
            employeeRow[EmployeeTableColumns.noHp] as String? ??
            employeeRow[EmployeeTableColumns.telepon] as String? ??
            employeeRow['no_hp'] as String? ??
            employeeRow['telepon'] as String? ??
            localUser?.phone ??
            '';
        final empEmail =
            employeeRow[EmployeeTableColumns.email] as String? ?? cleanEmail;
        final empAddress =
            employeeRow[EmployeeTableColumns.alamatLengkap] as String? ??
            localUser?.alamatLengkap;
        final empLat =
            (employeeRow['latitude'] as num?)?.toDouble() ??
            localUser?.latitude;
        final empLng =
            (employeeRow['longitude'] as num?)?.toDouble() ??
            localUser?.longitude;

        // Hitung riwayat tugas pengiriman kurir dari t_shipment_assignments
        int taskCount = 0;
        try {
          if (empId.isNotEmpty) {
            final res = await _client
                .from(DatabaseConstants.tableShipmentAssignments)
                .select(DatabaseConstants.colId)
                .eq('courier_id', empId);
            taskCount = (res as List).length;
          }
        } catch (_) {
          taskCount = 0;
        }

        final courierAccount = UserAccountModel(
          id: empId,
          name: empName,
          email: empEmail,
          phone: empPhone,
          fullAddress: empAddress,
          latitude: empLat,
          longitude: empLng,
          isEmailVerified: isEmailVerified,
          membershipTier: 'Kurir SatSet: $empCode',
          shipmentCount: taskCount,
          satsetPayBalance: 0,
          savedAddressesCount: empAddress != null && empAddress.isNotEmpty
              ? 1
              : 0,
          insuranceClaimsCount: 0,
          isNotificationsEnabled: true,
          isCourier: true,
        );

        _cachedAccount = courierAccount;
        return courierAccount;
      }

      // B. Jika profil ditemukan di m_users (AKUN CUSTOMER)
      if (userRow != null) {
        int shipmentCount = 0;
        try {
          final userId = userRow[UserTableColumns.id]?.toString();
          final userPhone = userRow[UserTableColumns.noHp]?.toString();

          if (userId != null && userId.isNotEmpty) {
            final res = await _client
                .from(DatabaseConstants.tableShipments)
                .select(ShipmentTableColumns.id)
                .or(
                  '${ShipmentTableColumns.customerId}.eq.$userId,${ShipmentTableColumns.pengirimNoHp}.eq.$userPhone',
                );
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
      }

      // C. Fallback jika userRow dan employeeRow null di Supabase, tapi data localUser tersedia
      if (localUser != null && localUser.isNotEmpty) {
        final fallbackLocal = UserAccountModel(
          id: localUser.id,
          name: localUser.name.isNotEmpty
              ? localUser.name
              : (isCourierHint ? 'Kurir SatSet' : 'Pelanggan SatSet'),
          email: localUser.email,
          phone: localUser.phone,
          fullAddress: localUser.alamatLengkap,
          latitude: localUser.latitude,
          longitude: localUser.longitude,
          isEmailVerified: isEmailVerified,
          membershipTier: isCourierHint
              ? 'Mitra Kurir SatSet'
              : 'SatSet Priority Member',
          shipmentCount: 0,
          satsetPayBalance: isCourierHint ? 0 : 450000,
          savedAddressesCount: localUser.alamatLengkap != null ? 1 : 0,
          isCourier: isCourierHint,
        );
        _cachedAccount = fallbackLocal;
        return fallbackLocal;
      }

      return _cachedAccount;
    } catch (_) {
      if (localUser != null && localUser.isNotEmpty) {
        final fallbackLocal = UserAccountModel(
          id: localUser.id,
          name: localUser.name.isNotEmpty
              ? localUser.name
              : (isCourierHint ? 'Kurir SatSet' : 'Pelanggan SatSet'),
          email: localUser.email,
          phone: localUser.phone,
          fullAddress: localUser.alamatLengkap,
          latitude: localUser.latitude,
          longitude: localUser.longitude,
          membershipTier: isCourierHint
              ? 'Mitra Kurir SatSet'
              : 'SatSet Priority Member',
          shipmentCount: 0,
          satsetPayBalance: isCourierHint ? 0 : 450000,
          isCourier: isCourierHint,
        );
        _cachedAccount = fallbackLocal;
        return fallbackLocal;
      }
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
      final cleanEmail = account.email.trim().toLowerCase();
      bool isEmployee = account.isCourierAccount;

      if (!isEmployee) {
        try {
          final empCheck = await _client
              .from(DatabaseConstants.tableEmployee)
              .select(DatabaseConstants.colId)
              .or(
                '${DatabaseConstants.colId}.eq.${account.id},email.eq.$cleanEmail',
              )
              .maybeSingle();
          if (empCheck != null) {
            isEmployee = true;
          }
        } catch (_) {}
      }

      if (isEmployee) {
        final updateData = <String, dynamic>{
          EmployeeTableColumns.namaLengkap: account.name,
          EmployeeTableColumns.nama: account.name,
          EmployeeTableColumns.noHp: account.phone,
          EmployeeTableColumns.telepon: account.phone,
          EmployeeTableColumns.email: cleanEmail,
          EmployeeTableColumns.updatedAt: DateTime.now().toIso8601String(),
        };

        if (account.fullAddress != null && account.fullAddress!.isNotEmpty) {
          updateData[EmployeeTableColumns.alamatLengkap] = account.fullAddress;
        }
        if (account.latitude != null) {
          updateData['latitude'] = account.latitude;
        }
        if (account.longitude != null) {
          updateData['longitude'] = account.longitude;
        }

        if (account.id.isNotEmpty &&
            account.id != 'usr-01' &&
            account.id != 'courier-01') {
          await _client
              .from(DatabaseConstants.tableEmployee)
              .update(updateData)
              .eq(DatabaseConstants.colId, account.id);
        } else {
          await _client
              .from(DatabaseConstants.tableEmployee)
              .update(updateData)
              .eq(EmployeeTableColumns.email, cleanEmail);
        }
      } else {
        final updateData = <String, dynamic>{
          UserTableColumns.namaLengkap: account.name,
          UserTableColumns.noHp: account.phone,
          UserTableColumns.email: cleanEmail,
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
              .eq(UserTableColumns.email, cleanEmail);
        }
      }

      // Sinkronkan ke local user jika tersimpan
      try {
        final authLocal = _authLocalDataSource ?? AuthLocalDataSourceImpl();
        final local = await authLocal.getUser();
        if (local != null) {
          final updatedLocal = local.copyWith(
            name: account.name,
            phone: account.phone,
            alamatLengkap: account.fullAddress,
            latitude: account.latitude,
            longitude: account.longitude,
          );
          await authLocal.saveUser(updatedLocal);
        }
      } catch (_) {}

      _cachedAccount = account;
    } catch (e) {
      _cachedAccount = account;
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    if (!_isSupabaseAvailable) return;

    try {
      // 1. Perbarui kata sandi melalui Supabase Auth
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (_) {}

    try {
      // 2. Sinkronkan hash kata sandi pada m_users dan m_employee jika kolom tersedia
      final authUser = _client.auth.currentUser;
      final localUser =
          currentUser ??
          await (_authLocalDataSource ?? AuthLocalDataSourceImpl()).getUser();
      final email = authUser?.email ?? localUser?.email ?? _cachedAccount.email;
      if (email.isNotEmpty) {
        final cleanEmail = email.trim().toLowerCase();
        final hashedPassword = PasswordHasher.hash(newPassword);
        final updatePayload = {
          'password': hashedPassword,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await _client
              .from(DatabaseConstants.tableUsers)
              .update(updatePayload)
              .eq(UserTableColumns.email, cleanEmail);
        } catch (_) {}

        try {
          await _client
              .from(DatabaseConstants.tableEmployee)
              .update(updatePayload)
              .eq(EmployeeTableColumns.email, cleanEmail);
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    if (!_isSupabaseAvailable) return;
    final cleanEmail = email.trim().toLowerCase();
    await _client.auth.resend(type: OtpType.signup, email: cleanEmail);
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
          .map<ProvinceModel>(
            (r) => ProvinceModel.fromDatabase(r as Map<String, dynamic>),
          )
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
        RegencyModel(
          code: '$provinceCode.01',
          provinceCode: provinceCode,
          name: 'Kota Administrasi Pusat',
          type: 'KOTA',
        ),
        RegencyModel(
          code: '$provinceCode.02',
          provinceCode: provinceCode,
          name: 'Kota Administrasi Selatan',
          type: 'KOTA',
        ),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKabkot)
          .select()
          .eq(KabkotTableColumns.kodeProvinsi, provinceCode)
          .order(KabkotTableColumns.namaKabkot, ascending: true);

      return (rows as List)
          .map<RegencyModel>(
            (r) => RegencyModel.fromDatabase(r as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DistrictModel>> getDistricts(String regencyCode) async {
    if (!_isSupabaseAvailable) {
      return [
        DistrictModel(
          code: '$regencyCode.01',
          regencyCode: regencyCode,
          name: 'Kecamatan Gambir',
        ),
        DistrictModel(
          code: '$regencyCode.02',
          regencyCode: regencyCode,
          name: 'Kecamatan Kebayoran Baru',
        ),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKecamatan)
          .select()
          .eq(KecamatanTableColumns.kodeKabkot, regencyCode)
          .order(KecamatanTableColumns.namaKecamatan, ascending: true);

      return (rows as List)
          .map<DistrictModel>(
            (r) => DistrictModel.fromDatabase(r as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VillageModel>> getVillages(String districtCode) async {
    if (!_isSupabaseAvailable) {
      return [
        VillageModel(
          code: '$districtCode.01',
          districtCode: districtCode,
          name: 'Kelurahan Senayan',
          postalCode: '10270',
        ),
        VillageModel(
          code: '$districtCode.02',
          districtCode: districtCode,
          name: 'Kelurahan Kebayoran',
          postalCode: '12110',
        ),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKelurahan)
          .select()
          .eq(KelurahanTableColumns.kodeKecamatan, districtCode)
          .order(KelurahanTableColumns.namaKelurahan, ascending: true);

      return (rows as List)
          .map<VillageModel>(
            (r) => VillageModel.fromDatabase(r as Map<String, dynamic>),
          )
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
