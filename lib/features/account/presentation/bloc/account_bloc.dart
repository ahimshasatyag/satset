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
    on<AccountLogoutSubmitted>(_onLogoutSubmitted);

    add(const AccountProfileLoaded());
  }

  Future<void> _onProfileLoaded(
    AccountProfileLoaded event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
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

  Future<void> _onLogoutSubmitted(
    AccountLogoutSubmitted event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
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
