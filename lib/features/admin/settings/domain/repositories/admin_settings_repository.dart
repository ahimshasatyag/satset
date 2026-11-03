import '../entities/admin_profile.dart';
import '../entities/admin_settings_data.dart';
import '../entities/company_profile.dart';
import '../entities/notification_preferences.dart';

abstract class AdminSettingsRepository {
  /// Verifikasi hak akses admin (m_employee.id_users_role = 1)
  Future<bool> verifyAdminAccess();

  /// Mengambil data konfigurasi lengkap settings
  Future<AdminSettingsData> getSettingsData();

  /// Memperbarui profil administrator pada m_employee
  Future<AdminProfile> updateAdminProfile({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  });

  /// Mengubah kata sandi administrator melalui Supabase Auth
  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Memperbarui informasi profil perusahaan
  Future<CompanyProfile> updateCompanyProfile(CompanyProfile profile);

  /// Memperbarui preferensi notifikasi admin
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  );

  /// Mengaktifkan / menonaktifkan jenis layanan pada m_service_types
  Future<void> toggleServiceTypeStatus({
    required int serviceTypeId,
    required bool isActive,
  });
}

