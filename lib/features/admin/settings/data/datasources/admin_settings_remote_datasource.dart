import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/models/admin_user_model.dart';

import '../../domain/entities/admin_profile.dart';
import '../../domain/entities/admin_settings_data.dart';
import '../../domain/entities/company_profile.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/operational_settings.dart';
import '../../domain/entities/system_info.dart';
import '../models/admin_profile_model.dart';
import '../models/company_profile_model.dart';
import '../models/notification_preferences_model.dart';
import '../models/operational_settings_model.dart';

abstract class AdminSettingsRemoteDataSource {
  Future<bool> verifyAdminAccess();
  Future<AdminSettingsData> getSettingsData();
  Future<AdminProfile> updateAdminProfile({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  });
  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<CompanyProfile> updateCompanyProfile(CompanyProfile profile);
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  );
  Future<void> toggleServiceTypeStatus({
    required int serviceTypeId,
    required bool isActive,
  });
}

class AdminSettingsRemoteDataSourceImpl
    implements AdminSettingsRemoteDataSource {
  final SupabaseClient _client;

  static const String _keyCompanySettings = 'KEY_SATSET_COMPANY_SETTINGS';
  static const String _keyNotificationPreferences =
      'KEY_SATSET_NOTIFICATION_PREFERENCES';

  AdminSettingsRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<bool> verifyAdminAccess() async {
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      final authUser = _client.auth.currentUser;

      if (savedAdmin != null &&
          (savedAdmin.idUsersRole == 1 || savedAdmin.role == 'admin')) {
        return true;
      }

      final email = (savedAdmin?.email.isNotEmpty == true)
          ? savedAdmin!.email
          : authUser?.email;

      if (email == null || email.isEmpty) {
        return false;
      }

      try {
        final empRes = await _client
            .from(DatabaseConstants.tableEmployee)
            .select('id, id_users_role, email, is_active')
            .eq(EmployeeTableColumns.email, email)
            .maybeSingle();

        if (empRes != null) {
          final roleId =
              int.tryParse(empRes['id_users_role']?.toString() ?? '');
          final isActive = empRes['is_active'] != false;
          if (roleId == 1 && isActive) {
            return true;
          }
        }
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requireAdminAuthorization() async {
    final allowed = await verifyAdminAccess();
    if (!allowed) {
      throw Exception(
        'Akses Ditolak: Halaman Pengaturan hanya dapat diakses oleh Administrator resmi (m_employee.id_users_role = 1).',
      );
    }
  }

  @override
  Future<AdminSettingsData> getSettingsData() async {
    await _requireAdminAuthorization();

    final localDataSource = AdminAuthLocalDataSourceImpl();
    final savedAdmin = await localDataSource.getAdmin();
    final authUser = _client.auth.currentUser;
    final email = savedAdmin?.email ?? authUser?.email ?? '';

    // 1. Ambil profil admin dari m_employee
    AdminProfile adminProfile;
    try {
      Map<String, dynamic>? empMap;
      if (email.isNotEmpty) {
        final res = await _client
            .from(DatabaseConstants.tableEmployee)
            .select('*')
            .eq(EmployeeTableColumns.email, email)
            .maybeSingle();
        if (res != null) {
          empMap = Map<String, dynamic>.from(res);
        }
      }

      if (empMap == null && savedAdmin != null) {
        final parsedId = int.tryParse(savedAdmin.id);
        if (parsedId != null && parsedId > 0) {
          final res = await _client
              .from(DatabaseConstants.tableEmployee)
              .select('*')
              .eq('id', parsedId)
              .maybeSingle();
          if (res != null) {
            empMap = Map<String, dynamic>.from(res);
          }
        }
      }

      if (empMap != null) {
        adminProfile = AdminProfileModel.fromMap(empMap);
      } else {
        adminProfile = AdminProfile(
          id: int.tryParse(savedAdmin?.id ?? '1') ?? 1,
          employeeCode: savedAdmin?.employeeCode ?? 'ADM-01',
          namaLengkap: savedAdmin?.name ?? 'Administrator SatSet',
          email: email.isNotEmpty ? email : 'admin@satset.id',
          noHp: savedAdmin?.phone ?? '08123456789',
          idUsersRole: 1,
          role: 'admin',
          employeeType: 'ADMIN',
          isActive: true,
        );
      }
    } catch (_) {
      adminProfile = AdminProfile(
        id: int.tryParse(savedAdmin?.id ?? '1') ?? 1,
        employeeCode: savedAdmin?.employeeCode ?? 'ADM-01',
        namaLengkap: savedAdmin?.name ?? 'Administrator SatSet',
        email: email.isNotEmpty ? email : 'admin@satset.id',
        noHp: savedAdmin?.phone ?? '08123456789',
        idUsersRole: 1,
        role: 'admin',
        employeeType: 'ADMIN',
        isActive: true,
      );
    }

    // 2. Ambil profil perusahaan dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyJson = prefs.getString(_keyCompanySettings);
    final companyProfile = CompanyProfileModel.fromJsonString(companyJson);

    // 3. Ambil data operasional: m_service_types & m_shipment_statuses
    List<ServiceTypeSettingItem> serviceTypes = [];
    try {
      final stRes = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select('*')
          .order('id', ascending: true);
      serviceTypes = (stRes as List)
          .map(
            (e) => ServiceTypeSettingItemModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {}

    List<ShipmentStatusSettingItem> shipmentStatuses = [];
    try {
      final ssRes = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode, nama_status, urutan')
          .order('urutan', ascending: true);
      shipmentStatuses = (ssRes as List)
          .map(
            (e) => ShipmentStatusSettingItemModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {}

    final operationalSettings = OperationalSettings(
      serviceTypes: serviceTypes,
      shipmentStatuses: shipmentStatuses,
      maxPackageWeightKg: 50,
      insuranceRatePercent: 0.2,
      autoConfirmCodShipments: false,
    );

    // 4. Ambil statistik notifikasi dari t_notifications & preferensi dari SharedPreferences
    int totalNotif = 0;
    int unreadNotif = 0;
    try {
      final notifRes = await _client
          .from(DatabaseConstants.tableNotifications)
          .select('id, is_read');
      final list = notifRes as List;
      totalNotif = list.length;
      for (final n in list) {
        if (n['is_read'] != true) unreadNotif++;
      }
    } catch (_) {}

    final notifJson = prefs.getString(_keyNotificationPreferences);
    final notificationPreferences =
        NotificationPreferencesModel.fromJsonString(
      notifJson,
      totalCount: totalNotif,
      unreadCount: unreadNotif,
    );

    // 5. Cek latensi dan status koneksi database
    final stopwatch = Stopwatch()..start();
    bool isConnected = true;
    try {
      await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id')
          .limit(1);
    } catch (_) {
      isConnected = false;
    }
    stopwatch.stop();

    final systemInfo = SystemInfo(
      appName: 'SatSet Delivery Admin Portal',
      appVersion: '1.0.0+1 (Web Edition)',
      flutterSdkVersion: 'Flutter 3.x (Dart 3.x)',
      backendPlatform: 'Supabase Cloud (PostgreSQL 15+)',
      databaseEngine: 'PostgreSQL RDBMS with Foreign Key Integrity',
      realtimeEngine: 'Supabase Realtime WebSockets',
      securityProtocol:
          'Row Level Security (RLS) & Role-Based Access Control (id_users_role = 1)',
      isDatabaseConnected: isConnected,
      databaseLatencyMs: stopwatch.elapsedMilliseconds,
      environment: 'Production Ready',
      lastCheckedAt: DateTime.now(),
    );

    return AdminSettingsData(
      adminProfile: adminProfile,
      companyProfile: companyProfile,
      operationalSettings: operationalSettings,
      notificationPreferences: notificationPreferences,
      systemInfo: systemInfo,
    );
  }

  @override
  Future<AdminProfile> updateAdminProfile({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  }) async {
    await _requireAdminAuthorization();

    final updatePayload = {
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_hp': noHp,
      'alamat_lengkap': ?alamatLengkap,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updatedRows = await _client
        .from(DatabaseConstants.tableEmployee)
        .update(updatePayload)
        .eq('id', adminId)
        .select('*');

    Map<String, dynamic> resultMap;
    if (updatedRows.isNotEmpty) {
      resultMap = Map<String, dynamic>.from(updatedRows.first as Map);
    } else {
      resultMap = {
        'id': adminId,
        'nama_lengkap': namaLengkap,
        'email': email,
        'no_hp': noHp,
        'alamat_lengkap': alamatLengkap,
        'id_users_role': 1,
        'role': 'admin',
        'is_active': true,
      };
    }

    final updatedModel = AdminProfileModel.fromMap(resultMap);

    // Sinkronkan ke local storage admin agar header dan sidebar langsung terupdate
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final currentSaved = await localDataSource.getAdmin();
      final updatedAdminUser = AdminUserModel(
        id: adminId.toString(),
        name: updatedModel.namaLengkap,
        email: updatedModel.email,
        phone: updatedModel.noHp,
        role: updatedModel.role,
        idUsersRole: updatedModel.idUsersRole,
        employeeCode: updatedModel.employeeCode,
        employeeType: updatedModel.employeeType,
        photoUrl: updatedModel.photoUrl,
        token: currentSaved?.token,
        isActive: updatedModel.isActive,
      );
      await localDataSource.saveAdmin(updatedAdminUser);
    } catch (_) {}

    return updatedModel;
  }

  @override
  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _requireAdminAuthorization();

    // 1. Perbarui kata sandi melalui Supabase Auth
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        await _client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      }
    } catch (e) {
      // Jika session auth Supabase kadaluarsa, lemparkan pesan yang informatif
      throw Exception(
        'Gagal memperbarui kata sandi melalui Supabase Auth: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }

    // 2. Jika kolom password pada m_employee digunakan untuk fallback login, perbarui juga
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      if (savedAdmin != null && savedAdmin.email.isNotEmpty) {
        await _client.from(DatabaseConstants.tableEmployee).update({
          'password': newPassword,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('email', savedAdmin.email);
      }
    } catch (_) {}
  }

  @override
  Future<CompanyProfile> updateCompanyProfile(CompanyProfile profile) async {
    await _requireAdminAuthorization();

    final prefs = await SharedPreferences.getInstance();
    final model = CompanyProfileModel(
      companyName: profile.companyName,
      operationalAddress: profile.operationalAddress,
      contactPhone: profile.contactPhone,
      contactEmail: profile.contactEmail,
      websiteUrl: profile.websiteUrl,
      operationalHours: profile.operationalHours,
      motto: profile.motto,
      legalEntityNumber: profile.legalEntityNumber,
      isStoredLocally: true,
      backendNote: profile.backendNote,
    );

    await prefs.setString(_keyCompanySettings, model.toJsonString());
    return model;
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    await _requireAdminAuthorization();

    final prefs = await SharedPreferences.getInstance();
    final model = NotificationPreferencesModel(
      notifyNewShipmentOrders: preferences.notifyNewShipmentOrders,
      notifyShipmentStatusChanges: preferences.notifyShipmentStatusChanges,
      notifyCourierAssignments: preferences.notifyCourierAssignments,
      notifyPaymentTransactions: preferences.notifyPaymentTransactions,
      notifyFailedDeliveries: preferences.notifyFailedDeliveries,
      soundAlertEnabled: preferences.soundAlertEnabled,
      totalExistingNotifications: preferences.totalExistingNotifications,
      unreadNotificationsCount: preferences.unreadNotificationsCount,
      backendNote: preferences.backendNote,
    );

    await prefs.setString(_keyNotificationPreferences, model.toJsonString());
    return model;
  }

  @override
  Future<void> toggleServiceTypeStatus({
    required int serviceTypeId,
    required bool isActive,
  }) async {
    await _requireAdminAuthorization();

    await _client.from(DatabaseConstants.tableServiceTypes).update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', serviceTypeId);
  }
}
