import '../../domain/entities/admin_profile.dart';
import '../../domain/entities/admin_settings_data.dart';
import '../../domain/entities/company_profile.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/admin_settings_repository.dart';
import '../datasources/admin_settings_remote_datasource.dart';

class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  final AdminSettingsRemoteDataSource remoteDataSource;

  const AdminSettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminSettingsData> getSettingsData() {
    return remoteDataSource.getSettingsData();
  }

  @override
  Future<AdminProfile> updateAdminProfile({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  }) {
    return remoteDataSource.updateAdminProfile(
      adminId: adminId,
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
    );
  }

  @override
  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changeAdminPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<CompanyProfile> updateCompanyProfile(CompanyProfile profile) {
    return remoteDataSource.updateCompanyProfile(profile);
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) {
    return remoteDataSource.updateNotificationPreferences(preferences);
  }

  @override
  Future<void> toggleServiceTypeStatus({
    required int serviceTypeId,
    required bool isActive,
  }) {
    return remoteDataSource.toggleServiceTypeStatus(
      serviceTypeId: serviceTypeId,
      isActive: isActive,
    );
  }
}

