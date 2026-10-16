import '../../domain/entities/app_settings_entity.dart';

/// Model Data Transfer Object (DTO) untuk AppSettings,
/// turunan dari [AppSettingsEntity] dengan serialisasi JSON.
class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    required super.isAuthenticated,
    required super.isFirstTime,
    required super.appVersion,
    required super.appName,
  });

  /// Mengonversi dari Map / JSON (misal dari cache lokal atau response API)
  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      isFirstTime: json['is_first_time'] as bool? ?? true,
      appVersion: json['app_version'] as String? ?? '1.0.0',
      appName: json['app_name'] as String? ?? 'SatSet Express',
    );
  }

  /// Mengonversi ke Map / JSON untuk disimpan di penyimpanan lokal
  Map<String, dynamic> toJson() {
    return {
      'is_authenticated': isAuthenticated,
      'is_first_time': isFirstTime,
      'app_version': appVersion,
      'app_name': appName,
    };
  }

  /// Membuat model dari entity
  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      isAuthenticated: entity.isAuthenticated,
      isFirstTime: entity.isFirstTime,
      appVersion: entity.appVersion,
      appName: entity.appName,
    );
  }
}
