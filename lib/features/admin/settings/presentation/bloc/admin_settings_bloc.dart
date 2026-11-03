import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operational_settings.dart';
import '../../domain/repositories/admin_settings_repository.dart';
import '../../domain/usecases/change_admin_password_usecase.dart';
import '../../domain/usecases/get_admin_settings_usecase.dart';
import '../../domain/usecases/toggle_service_type_active_usecase.dart';
import '../../domain/usecases/update_admin_profile_usecase.dart';
import '../../domain/usecases/update_company_profile_usecase.dart';
import '../../domain/usecases/update_notification_preferences_usecase.dart';
import 'admin_settings_event.dart';
import 'admin_settings_state.dart';

class AdminSettingsBloc extends Bloc<AdminSettingsEvent, AdminSettingsState> {
  final AdminSettingsRepository repository;
  final GetAdminSettingsUseCase _getSettingsUseCase;
  final UpdateAdminProfileUseCase _updateProfileUseCase;
  final ChangeAdminPasswordUseCase _changePasswordUseCase;
  final UpdateCompanyProfileUseCase _updateCompanyUseCase;
  final UpdateNotificationPreferencesUseCase _updateNotificationUseCase;
  final ToggleServiceTypeActiveUseCase _toggleServiceTypeUseCase;

  AdminSettingsBloc({required this.repository})
      : _getSettingsUseCase = GetAdminSettingsUseCase(repository),
        _updateProfileUseCase = UpdateAdminProfileUseCase(repository),
        _changePasswordUseCase = ChangeAdminPasswordUseCase(repository),
        _updateCompanyUseCase = UpdateCompanyProfileUseCase(repository),
        _updateNotificationUseCase =
            UpdateNotificationPreferencesUseCase(repository),
        _toggleServiceTypeUseCase =
            ToggleServiceTypeActiveUseCase(repository),
        super(const AdminSettingsState()) {
    on<AdminSettingsStarted>(_onStarted);
    on<AdminSettingsRefreshed>(_onRefreshed);
    on<AdminSettingsTabChanged>(_onTabChanged);
    on<AdminSettingsProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AdminSettingsPasswordChangeRequested>(_onPasswordChangeRequested);
    on<AdminSettingsCompanyUpdateRequested>(_onCompanyUpdateRequested);
    on<AdminSettingsNotificationPreferencesUpdated>(
      _onNotificationPreferencesUpdated,
    );
    on<AdminSettingsServiceTypeToggled>(_onServiceTypeToggled);
    on<AdminSettingsClearFeedback>(_onClearFeedback);
  }

  Future<void> _onStarted(
    AdminSettingsStarted event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminSettingsStatus.loading,
        clearErrorMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    final isAuthorized = await repository.verifyAdminAccess();
    if (!isAuthorized) {
      emit(
        state.copyWith(
          status: AdminSettingsStatus.unauthorized,
          errorMessage:
              'Akses Ditolak: Halaman Pengaturan hanya dapat diakses oleh Administrator resmi (m_employee.id_users_role = 1).',
        ),
      );
      return;
    }

    try {
      final data = await _getSettingsUseCase();
      emit(
        state.copyWith(
          status: AdminSettingsStatus.loaded,
          settingsData: data,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminSettingsStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    AdminSettingsRefreshed event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearActionErrorMessage: true));
    try {
      final data = await _getSettingsUseCase();
      emit(
        state.copyWith(
          status: AdminSettingsStatus.loaded,
          settingsData: data,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onTabChanged(
    AdminSettingsTabChanged event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(state.copyWith(activeTabIndex: event.tabIndex));
  }

  Future<void> _onProfileUpdateRequested(
    AdminSettingsProfileUpdateRequested event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isSaving: true,
        clearSuccessMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final updatedProfile = await _updateProfileUseCase(
        adminId: event.adminId,
        namaLengkap: event.namaLengkap,
        email: event.email,
        noHp: event.noHp,
        alamatLengkap: event.alamatLengkap,
      );

      final currentSettings = state.settingsData;
      final newSettings = currentSettings?.copyWith(
        adminProfile: updatedProfile,
      );

      emit(
        state.copyWith(
          isSaving: false,
          settingsData: newSettings,
          successMessage: 'Profil Administrator berhasil diperbarui.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPasswordChangeRequested(
    AdminSettingsPasswordChangeRequested event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isSaving: true,
        clearSuccessMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _changePasswordUseCase(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      emit(
        state.copyWith(
          isSaving: false,
          successMessage:
              'Kata sandi Administrator berhasil diubah melalui Supabase Auth.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCompanyUpdateRequested(
    AdminSettingsCompanyUpdateRequested event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isSaving: true,
        clearSuccessMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final updatedCompany = await _updateCompanyUseCase(event.companyProfile);
      final currentSettings = state.settingsData;
      final newSettings = currentSettings?.copyWith(
        companyProfile: updatedCompany,
      );

      emit(
        state.copyWith(
          isSaving: false,
          settingsData: newSettings,
          successMessage: 'Informasi profil perusahaan berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onNotificationPreferencesUpdated(
    AdminSettingsNotificationPreferencesUpdated event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isSaving: true,
        clearSuccessMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final updatedPrefs = await _updateNotificationUseCase(
        event.notificationPreferences,
      );
      final currentSettings = state.settingsData;
      final newSettings = currentSettings?.copyWith(
        notificationPreferences: updatedPrefs,
      );

      emit(
        state.copyWith(
          isSaving: false,
          settingsData: newSettings,
          successMessage: 'Preferensi notifikasi admin berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onServiceTypeToggled(
    AdminSettingsServiceTypeToggled event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(clearSuccessMessage: true, clearActionErrorMessage: true));

    try {
      await _toggleServiceTypeUseCase(
        serviceTypeId: event.serviceTypeId,
        isActive: event.isActive,
      );

      // Sinkronkan state lokal
      final currentSettings = state.settingsData;
      if (currentSettings != null) {
        final updatedList = currentSettings.operationalSettings.serviceTypes
            .map((s) {
          if (s.id == event.serviceTypeId) {
            return ServiceTypeSettingItem(
              id: s.id,
              kode: s.kode,
              namaLayanan: s.namaLayanan,
              estimasiHariMin: s.estimasiHariMin,
              estimasiHariMax: s.estimasiHariMax,
              deskripsi: s.deskripsi,
              isActive: event.isActive,
              baseTariffPerKg: s.baseTariffPerKg,
              createdAt: s.createdAt,
            );
          }
          return s;
        }).toList();

        final updatedOp = currentSettings.operationalSettings.copyWith(
          serviceTypes: updatedList,
        );
        emit(
          state.copyWith(
            settingsData: currentSettings.copyWith(operationalSettings: updatedOp),
            successMessage:
                'Status layanan berhasil di${event.isActive ? 'aktifkan' : 'nonaktifkan'} untuk pesanan baru.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onClearFeedback(
    AdminSettingsClearFeedback event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        clearSuccessMessage: true,
        clearActionErrorMessage: true,
      ),
    );
  }
}
