import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_settings_data.dart';

enum AdminSettingsStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminSettingsState extends Equatable {
  final AdminSettingsStatus status;
  final AdminSettingsData? settingsData;
  final int activeTabIndex;
  final bool isSaving;
  final bool isRefreshing;
  final String? errorMessage;
  final String? successMessage;
  final String? actionErrorMessage;

  const AdminSettingsState({
    this.status = AdminSettingsStatus.initial,
    this.settingsData,
    this.activeTabIndex = 0,
    this.isSaving = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.successMessage,
    this.actionErrorMessage,
  });

  AdminSettingsState copyWith({
    AdminSettingsStatus? status,
    AdminSettingsData? settingsData,
    int? activeTabIndex,
    bool? isSaving,
    bool? isRefreshing,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) {
    return AdminSettingsState(
      status: status ?? this.status,
      settingsData: settingsData ?? this.settingsData,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isSaving: isSaving ?? this.isSaving,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        settingsData,
        activeTabIndex,
        isSaving,
        isRefreshing,
        errorMessage,
        successMessage,
        actionErrorMessage,
      ];
}

