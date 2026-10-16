import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/splash_repository.dart';
import '../datasources/splash_local_datasource.dart';

/// Implementasi [SplashRepository] yang menghubungkan domain ke data source
class SplashRepositoryImpl implements SplashRepository {
  final SplashLocalDataSource localDataSource;

  SplashRepositoryImpl({required this.localDataSource});

  @override
  Future<AppSettingsEntity> getAppSettings() async {
    final model = await localDataSource.getAppSettings();
    // Model adalah turunan dari entity, sehingga otomatis memenuhi kontrak entity
    return model;
  }

  @override
  Future<bool> checkAuthStatus() async {
    return await localDataSource.checkAuthStatus();
  }

  @override
  Future<void> setFirstTime(bool isFirstTime) async {
    await localDataSource.setFirstTime(isFirstTime);
  }
}
