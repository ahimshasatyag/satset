import 'package:equatable/equatable.dart';
import 'admin_profile.dart';
import 'company_profile.dart';
import 'notification_preferences.dart';
import 'operational_settings.dart';
import 'system_info.dart';

class AdminSettingsData extends Equatable {
  final AdminProfile adminProfile;
  final CompanyProfile companyProfile;
  final OperationalSettings operationalSettings;
  final NotificationPreferences notificationPreferences;
  final SystemInfo systemInfo;

  const AdminSettingsData({
    required this.adminProfile,
    required this.companyProfile,
    required this.operationalSettings,
    required this.notificationPreferences,
    required this.systemInfo,
  });

  AdminSettingsData copyWith({
    AdminProfile? adminProfile,
    CompanyProfile? companyProfile,
    OperationalSettings? operationalSettings,
    NotificationPreferences? notificationPreferences,
    SystemInfo? systemInfo,
  }) {
    return AdminSettingsData(
      adminProfile: adminProfile ?? this.adminProfile,
      companyProfile: companyProfile ?? this.companyProfile,
      operationalSettings: operationalSettings ?? this.operationalSettings,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      systemInfo: systemInfo ?? this.systemInfo,
    );
  }

  @override
  List<Object?> get props => [
        adminProfile,
        companyProfile,
        operationalSettings,
        notificationPreferences,
        systemInfo,
      ];
}

