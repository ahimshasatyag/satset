import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/social_login_buttons.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// Halaman Login Utama SatSet
class LoginPage extends StatelessWidget {
  final void Function(User user)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<AuthBloc>();
      return LoginView(onLoginSuccess: onLoginSuccess);
    } catch (_) {
      final localDataSource = AuthLocalDataSourceImpl();
      final remoteDataSource = AuthRemoteDataSourceImpl();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      return BlocProvider(
        create: (context) => AuthBloc(
          loginUseCase: LoginUseCase(repository),
          registerUseCase: RegisterUseCase(repository),
          logoutUseCase: LogoutUseCase(repository),
          getCurrentUserUseCase: GetCurrentUserUseCase(repository),
          repository: repository,
        )..add(const AuthCheckRequested()),
        child: LoginView(onLoginSuccess: onLoginSuccess),
      );
    }
  }
}

class LoginView extends StatefulWidget {
  final void Function(User user)? onLoginSuccess;

  const LoginView({super.key, this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _userInitiatedLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state is AuthSuccess) {
          authBloc.add(const AuthResetState());
        }
      }
    });
  }

  bool _hasPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage('assets/images/Background.png'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background motif dari Background.png dengan gaplessPlayback agar tidak sempat hilang saat rebuild
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // Lapisan overlay halus untuk mode gelap agar teks & card tetap kontras optimal
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && _userInitiatedLogin) {
            _userInitiatedLogin = false;
            CustomDialog.showSuccess(
              context: context,
              title: 'Login Berhasil! 🎉',
              message: state.message,
              confirmText: 'Lanjutkan ke Dashboard',
              onConfirm: () {
                if (widget.onLoginSuccess != null) {
                  widget.onLoginSuccess!(state.user);
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            );
          } else if (state is AuthFailure && _userInitiatedLogin) {
            _userInitiatedLogin = false;
            CustomDialog.showError(
              context: context,
              title: 'Gagal Masuk',
              message: state.errorMessage,
              confirmText: 'Coba Lagi',
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final savedEmail = state is AuthUnauthenticated
              ? state.savedEmail
              : null;
          final isRememberMe = state is AuthUnauthenticated
              ? state.rememberMe
              : false;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Brand SatSet
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/LogoTextSatset.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Judul Halaman
                      Center(
                        child: Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomCard(
                        variant: CardVariant.elevated,
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Form Login (Email, Password, Remember Me, Submit)
                            LoginForm(
                              initialEmail: savedEmail,
                              initialRememberMe: isRememberMe,
                              isLoading: isLoading,
                              onLogin: (email, password, rememberMe) {
                                _userInitiatedLogin = true;
                                context.read<AuthBloc>().add(
                                  AuthLoginSubmitted(
                                    email: email,
                                    password: password,
                                    rememberMe: rememberMe,
                                  ),
                                );
                              },
                              onForgotPasswordTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    child: BlocProvider.value(
                                      value: context.read<AuthBloc>(),
                                      child: const ForgotPasswordPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Alternatif Login via Google
                            SocialLoginButtons(
                              isLoading: isLoading,
                              onGooglePressed: () {
                                _userInitiatedLogin = true;
                                context.read<AuthBloc>().add(
                                  const AuthGoogleLoginSubmitted(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Footer: Tautan Pendaftaran
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun SatSet? ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    child: BlocProvider.value(
                                      value: context.read<AuthBloc>(),
                                      child: const RegisterPage(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Daftar Sekarang',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
);
  }
}
