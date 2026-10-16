import '../entities/app_settings_entity.dart';
import '../repositories/splash_repository.dart';

/// Use case untuk mengambil data konfigurasi dan pengaturan awal aplikasi
class GetAppSettingsUseCase {
  final SplashRepository repository;

  GetAppSettingsUseCase(this.repository);

  Future<AppSettingsEntity> call() async {
    return await repository.getAppSettings();
  }
}
