import 'package:equatable/equatable.dart';

/// Entity bisnis untuk menampung pengaturan awal aplikasi, status autentikasi,
/// dan informasi versi saat aplikasi pertama kali dibuka.
class AppSettingsEntity extends Equatable {
  final bool isAuthenticated;
  final bool isFirstTime;
  final String appVersion;
  final String appName;

  const AppSettingsEntity({
    required this.isAuthenticated,
    required this.isFirstTime,
    required this.appVersion,
    required this.appName,
  });

  /// Nilai default pengaturan awal
  const AppSettingsEntity.initial()
      : isAuthenticated = false,
        isFirstTime = true,
        appVersion = '1.0.0',
        appName = 'SatSet Express';

  AppSettingsEntity copyWith({
    bool? isAuthenticated,
    bool? isFirstTime,
    String? appVersion,
    String? appName,
  }) {
    return AppSettingsEntity(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      appVersion: appVersion ?? this.appVersion,
      appName: appName ?? this.appName,
    );
  }

  @override
  List<Object?> get props => [
        isAuthenticated,
        isFirstTime,
        appVersion,
        appName,
      ];
}
