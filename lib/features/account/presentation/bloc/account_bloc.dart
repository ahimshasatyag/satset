import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/get_user_account_usecase.dart';
import '../../domain/usecases/logout_account_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetUserAccountUseCase getUserAccountUseCase;
  final LogoutAccountUseCase logoutAccountUseCase;
  final AccountRepository repository;

  AccountBloc({
    required this.getUserAccountUseCase,
    required this.logoutAccountUseCase,
    required this.repository,
  }) : super(const AccountState()) {
    on<AccountProfileLoaded>(_onProfileLoaded);
    on<AccountNotificationsToggled>(_onNotificationsToggled);
    on<AccountProfileUpdated>(_onProfileUpdated);
    on<AccountPasswordChanged>(_onPasswordChanged);
    on<AccountEmailVerificationResent>(_onEmailVerificationResent);
    on<AccountAddressSaved>(_onAddressSaved);
    on<AccountAddressDeleted>(_onAddressDeleted);
    on<AccountPrimaryAddressSet>(_onPrimaryAddressSet);
    on<AccountLogoutSubmitted>(_onLogoutSubmitted);

    add(const AccountProfileLoaded());
  }

  Future<void> _onProfileLoaded(
    AccountProfileLoaded event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final account = await getUserAccountUseCase();
      emit(state.copyWith(account: account, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat profil akun: ${e.toString()}',
      ));
    }
  }

  Future<void> _onNotificationsToggled(
    AccountNotificationsToggled event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await repository.setNotificationsEnabled(event.isEnabled);
      if (state.account != null) {
        emit(state.copyWith(
          account: state.account!.copyWith(
            isNotificationsEnabled: event.isEnabled,
          ),
          notificationMessage: event.isEnabled
              ? 'Notifikasi berhasil diaktifkan.'
              : 'Notifikasi dinonaktifkan.',
        ));
      }
    } catch (_) {}
  }

  Future<void> _onProfileUpdated(
    AccountProfileUpdated event,
    Emitter<AccountState> emit,
  ) async {
    final current = state.account;
    if (current == null) return;

    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      final updated = current.copyWith(
        name: event.name.trim(),
        phone: event.phone.trim(),
        email: event.email != null && event.email!.trim().isNotEmpty
            ? event.email!.trim()
            : current.email,
      );
      await repository.updateAccount(updated);
      emit(state.copyWith(
        account: updated,
        isActionLoading: false,
        actionSuccessMessage: 'Profil berhasil diperbarui.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal memperbarui profil: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPasswordChanged(
    AccountPasswordChanged event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      await repository.changePassword(event.newPassword);
      emit(state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: 'Kata sandi berhasil diubah.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal mengubah kata sandi: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEmailVerificationResent(
    AccountEmailVerificationResent event,
    Emitter<AccountState> emit,
  ) async {
    final email = state.account?.email;
    if (email == null || email.isEmpty) return;

    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      await repository.resendEmailVerification(email);
      emit(state.copyWith(
        isActionLoading: false,
        actionSuccessMessage:
            'Tautan verifikasi email telah dikirim ke $email.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal mengirim email verifikasi: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddressSaved(
    AccountAddressSaved event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      await repository.saveAddress(event.address);
      final refreshed = await repository.getUserAccount();
      emit(state.copyWith(
        account: refreshed,
        isActionLoading: false,
        actionSuccessMessage: 'Alamat berhasil disimpan.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal menyimpan alamat: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddressDeleted(
    AccountAddressDeleted event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      await repository.deleteAddress(event.addressId);
      final refreshed = await repository.getUserAccount();
      emit(state.copyWith(
        account: refreshed,
        isActionLoading: false,
        actionSuccessMessage: 'Alamat berhasil dihapus.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal menghapus alamat: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPrimaryAddressSet(
    AccountPrimaryAddressSet event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(
      isActionLoading: true,
      clearError: true,
      clearActionSuccess: true,
    ));

    try {
      await repository.setPrimaryAddress(event.addressId);
      final refreshed = await repository.getUserAccount();
      emit(state.copyWith(
        account: refreshed,
        isActionLoading: false,
        actionSuccessMessage: 'Alamat utama berhasil ditetapkan.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: 'Gagal menetapkan alamat utama: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLogoutSubmitted(
    AccountLogoutSubmitted event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await logoutAccountUseCase();
      emit(state.copyWith(isLoading: false, isLoggedOut: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal keluar: ${e.toString()}',
      ));
    }
  }
}
