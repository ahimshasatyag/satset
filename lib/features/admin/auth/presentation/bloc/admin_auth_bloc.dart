import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_auth_repository.dart';
import '../../domain/usecases/admin_login_usecase.dart';
import '../../domain/usecases/admin_logout_usecase.dart';
import '../../domain/usecases/get_current_admin_usecase.dart';
import 'admin_auth_event.dart';
import 'admin_auth_state.dart';

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminLoginUseCase loginUseCase;
  final GetCurrentAdminUseCase getCurrentAdminUseCase;
  final AdminLogoutUseCase logoutUseCase;
  final AdminAuthRepository repository;

  AdminAuthBloc({
    required this.loginUseCase,
    required this.getCurrentAdminUseCase,
    required this.logoutUseCase,
    required this.repository,
  }) : super(const AdminAuthInitial()) {
    on<AdminAuthLoginSubmitted>(_onLoginSubmitted);
    on<AdminAuthCheckRequested>(_onCheckRequested);
    on<AdminAuthLogoutRequested>(_onLogoutRequested);
    on<AdminAuthResetState>(_onResetState);
  }

  Future<void> _onLoginSubmitted(
    AdminAuthLoginSubmitted event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(const AdminAuthLoading(message: 'Memvalidasi kredensial administrator...'));

    try {
      final adminUser = await loginUseCase.execute(
        email: event.email,
        password: event.password,
      );

      await repository.saveRememberMe(
        email: event.email,
        remember: event.rememberMe,
      );

      emit(AdminAuthSuccess(
        adminUser: adminUser,
        message: 'Otorisasi Berhasil. Membuka Portal Administrator...',
      ));
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '').trim();
      emit(AdminAuthFailure(errorMessage: cleanMsg));
    }
  }

  Future<void> _onCheckRequested(
    AdminAuthCheckRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      final rememberData = await repository.getRememberMe();
      final savedEmail = rememberData['email'] as String?;
      final rememberMe = rememberData['rememberMe'] as bool? ?? false;

      final currentAdmin = await getCurrentAdminUseCase.execute();
      if (currentAdmin != null) {
        emit(AdminAuthSuccess(adminUser: currentAdmin));
      } else {
        emit(AdminAuthUnauthenticated(
          savedEmail: savedEmail,
          rememberMe: rememberMe,
        ));
      }
    } catch (_) {
      emit(const AdminAuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AdminAuthLogoutRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(const AdminAuthLoading(message: 'Mengakhiri sesi administrator...'));
    try {
      await logoutUseCase.execute();
    } catch (_) {}
    emit(const AdminAuthUnauthenticated());
  }

  void _onResetState(
    AdminAuthResetState event,
    Emitter<AdminAuthState> emit,
  ) {
    emit(const AdminAuthInitial());
  }
}

