import 'package:equatable/equatable.dart';
import '../../domain/entities/company_profile.dart';
import '../../domain/entities/notification_preferences.dart';

abstract class AdminSettingsEvent extends Equatable {
  const AdminSettingsEvent();

  @override
  List<Object?> get props => [];
}

class AdminSettingsStarted extends AdminSettingsEvent {
  const AdminSettingsStarted();
}

class AdminSettingsRefreshed extends AdminSettingsEvent {
  const AdminSettingsRefreshed();
}

class AdminSettingsTabChanged extends AdminSettingsEvent {
  final int tabIndex;

  const AdminSettingsTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class AdminSettingsProfileUpdateRequested extends AdminSettingsEvent {
  final int adminId;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;

  const AdminSettingsProfileUpdateRequested({
    required this.adminId,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
  });

  @override
  List<Object?> get props => [
        adminId,
        namaLengkap,
        email,
        noHp,
        alamatLengkap,
      ];
}

class AdminSettingsPasswordChangeRequested extends AdminSettingsEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const AdminSettingsPasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [
        currentPassword,
        newPassword,
        confirmPassword,
      ];
}

class AdminSettingsCompanyUpdateRequested extends AdminSettingsEvent {
  final CompanyProfile companyProfile;

  const AdminSettingsCompanyUpdateRequested(this.companyProfile);

  @override
  List<Object?> get props => [companyProfile];
}

class AdminSettingsNotificationPreferencesUpdated extends AdminSettingsEvent {
  final NotificationPreferences notificationPreferences;

  const AdminSettingsNotificationPreferencesUpdated(
    this.notificationPreferences,
  );

  @override
  List<Object?> get props => [notificationPreferences];
}

class AdminSettingsServiceTypeToggled extends AdminSettingsEvent {
  final int serviceTypeId;
  final bool isActive;

  const AdminSettingsServiceTypeToggled({
    required this.serviceTypeId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [serviceTypeId, isActive];
}

class AdminSettingsClearFeedback extends AdminSettingsEvent {
  const AdminSettingsClearFeedback();
}

