import '../entities/app_settings_entity.dart';

/// Interface kontrak repository untuk fitur Splash & Onboarding
abstract class SplashRepository {
  /// Mengambil pengaturan awal aplikasi (status login, versi, status first time)
  Future<AppSettingsEntity> getAppSettings();

  /// Memeriksa apakah pengguna telah terautentikasi / login
  Future<bool> checkAuthStatus();

  /// Menyimpan status apakah onboarding pertama kali telah diselesaikan
  Future<void> setFirstTime(bool isFirstTime);
}
