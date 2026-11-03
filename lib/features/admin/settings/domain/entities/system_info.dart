import 'package:equatable/equatable.dart';

class SystemInfo extends Equatable {
  final String appName;
  final String appVersion;
  final String flutterSdkVersion;
  final String backendPlatform;
  final String databaseEngine;
  final String realtimeEngine;
  final String securityProtocol;
  final bool isDatabaseConnected;
  final int databaseLatencyMs;
  final String environment;
  final DateTime? lastCheckedAt;

  const SystemInfo({
    this.appName = 'SatSet Delivery Admin Portal',
    this.appVersion = '1.0.0+1 (Web Edition)',
    this.flutterSdkVersion = 'Flutter 3.x (Dart 3.x)',
    this.backendPlatform = 'Supabase Cloud (PostgreSQL 15+)',
    this.databaseEngine = 'PostgreSQL RDBMS with Foreign Key Integrity',
    this.realtimeEngine = 'Supabase Realtime WebSockets (Postgres Changes)',
    this.securityProtocol =
        'Row Level Security (RLS) & Role-Based Access Control (id_users_role = 1)',
    this.isDatabaseConnected = true,
    this.databaseLatencyMs = 45,
    this.environment = 'Production Ready',
    this.lastCheckedAt,
  });

  SystemInfo copyWith({
    String? appName,
    String? appVersion,
    String? flutterSdkVersion,
    String? backendPlatform,
    String? databaseEngine,
    String? realtimeEngine,
    String? securityProtocol,
    bool? isDatabaseConnected,
    int? databaseLatencyMs,
    String? environment,
    DateTime? lastCheckedAt,
  }) {
    return SystemInfo(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      backendPlatform: backendPlatform ?? this.backendPlatform,
      databaseEngine: databaseEngine ?? this.databaseEngine,
      realtimeEngine: realtimeEngine ?? this.realtimeEngine,
      securityProtocol: securityProtocol ?? this.securityProtocol,
      isDatabaseConnected: isDatabaseConnected ?? this.isDatabaseConnected,
      databaseLatencyMs: databaseLatencyMs ?? this.databaseLatencyMs,
      environment: environment ?? this.environment,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  List<Object?> get props => [
        appName,
        appVersion,
        flutterSdkVersion,
        backendPlatform,
        databaseEngine,
        realtimeEngine,
        securityProtocol,
        isDatabaseConnected,
        databaseLatencyMs,
        environment,
        lastCheckedAt,
      ];
}

