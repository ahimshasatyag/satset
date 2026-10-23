import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC untuk mengelola logika bisnis dan state autentikasi SatSet
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.repository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthCourierRegisterSubmitted>(_onCourierRegisterSubmitted);
    on<AuthGoogleLoginSubmitted>(_onGoogleLoginSubmitted);
    on<AuthForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<AuthVerifyCodeSubmitted>(_onVerifyCodeSubmitted);
    on<AuthResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<AuthResendCodeSubmitted>(_onResendCodeSubmitted);
    on<AuthLogoutSubmitted>(_onLogoutSubmitted);
    on<AuthResetState>(_onResetState);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Memeriksa sesi...'));
    try {
      final user = await getCurrentUserUseCase();
      final isRememberMe = await repository.isRememberMe();

      if (user != null && isRememberMe) {
        emit(AuthSuccess(user: user, message: 'Sesi aktif ditemukan'));
      } else {
        emit(AuthUnauthenticated(rememberMe: isRememberMe));
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Memverifikasi akun...'));
    try {
      final user = await loginUseCase(
        LoginParams(
          email: event.email.trim(),
          password: event.password,
          rememberMe: event.rememberMe,
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      );
      emit(AuthSuccess(
        user: user,
        message: 'Selamat datang kembali, ${user.name}!',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mendaftarkan akun baru...'));
    try {
      final user = await registerUseCase(
        RegisterParams(
          name: event.name.trim(),
          email: event.email.trim(),
          phone: event.phone.trim(),
          password: event.password,
          alamatLengkap: event.alamatLengkap?.trim(),
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      );
      emit(AuthSuccess(
        user: user,
        message: 'Pendaftaran akun SatSet berhasil!',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onCourierRegisterSubmitted(
    AuthCourierRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mendaftarkan akun kurir baru...'));
    try {
      final user = await repository.registerCourier(
        name: event.name.trim(),
        email: event.email.trim(),
        phone: event.phone.trim(),
        password: event.password,
        alamatLengkap: event.alamatLengkap?.trim(),
        latitude: event.latitude,
        longitude: event.longitude,
      );
      emit(AuthSuccess(
        user: user,
        message: 'Pendaftaran akun kurir SatSet berhasil!',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onGoogleLoginSubmitted(
    AuthGoogleLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Menghubungkan ke Google...'));
    try {
      final user = await loginUseCase.withGoogle();
      emit(AuthSuccess(
        user: user,
        message: 'Berhasil masuk dengan akun Google!',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onForgotPasswordSubmitted(
    AuthForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mengirim email reset kata sandi...'));
    try {
      await repository.forgotPassword(event.email.trim());
      emit(AuthForgotPasswordSuccess(event.email.trim()));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onVerifyCodeSubmitted(
    AuthVerifyCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Memverifikasi kode unik...'));
    try {
      await repository.verifyResetCode(
        email: event.email.trim(),
        code: event.code.trim(),
      );
      emit(AuthCodeVerifiedSuccess(
        email: event.email.trim(),
        code: event.code.trim(),
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    AuthResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Menyimpan kata sandi baru...'));
    try {
      await repository.resetPassword(
        email: event.email.trim(),
        code: event.code.trim(),
        newPassword: event.newPassword,
      );
      emit(const AuthResetPasswordSuccess());
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onResendCodeSubmitted(
    AuthResendCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mengirim ulang kode unik...'));
    try {
      await repository.resendVerificationCode(event.email.trim());
      emit(AuthResendCodeSuccess(email: event.email.trim()));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }

  Future<void> _onLogoutSubmitted(
    AuthLogoutSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Keluar...'));
    await logoutUseCase();
    emit(const AuthUnauthenticated());
  }

  void _onResetState(
    AuthResetState event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthInitial());
  }
}
