import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_remote_datasource.dart';
import 'package:satset/features/admin/auth/data/repositories/admin_auth_repository_impl.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_login_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_logout_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_register_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_bloc.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_state.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_email_verification_page.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import 'package:satset/shared/widgets/dialogs/status_animation.dart';

import '../widgets/admin_register_card.dart';
import '../widgets/admin_register_header.dart';

class AdminRegisterPage extends StatelessWidget {
  final void Function(User user)? onRegisterSuccess;
  final VoidCallback? onNavigateToLogin;

  const AdminRegisterPage({
    super.key,
    this.onRegisterSuccess,
    this.onNavigateToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminAuthRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final localDataSource = AdminAuthLocalDataSourceImpl();
    final repository = AdminAuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final loginUseCase = AdminLoginUseCase(repository);
    final registerUseCase = AdminRegisterUseCase(repository);
    final getCurrentAdminUseCase = GetCurrentAdminUseCase(repository);
    final logoutUseCase = AdminLogoutUseCase(repository);

    return BlocProvider(
      create: (context) => AdminAuthBloc(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        getCurrentAdminUseCase: getCurrentAdminUseCase,
        logoutUseCase: logoutUseCase,
        repository: repository,
      ),
      child: AdminRegisterView(
        onRegisterSuccess: onRegisterSuccess,
        onNavigateToLogin: onNavigateToLogin,
      ),
    );
  }
}

class AdminRegisterView extends StatefulWidget {
  final void Function(User user)? onRegisterSuccess;
  final VoidCallback? onNavigateToLogin;

  const AdminRegisterView({
    super.key,
    this.onRegisterSuccess,
    this.onNavigateToLogin,
  });

  @override
  State<AdminRegisterView> createState() => _AdminRegisterViewState();
}

class _AdminRegisterViewState extends State<AdminRegisterView> {
  void _navigateToLogin(BuildContext context) {
    if (widget.onNavigateToLogin != null) {
      widget.onNavigateToLogin!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }
  }

  void _navigateToVerification(
    BuildContext context,
    AdminAuthSuccess state,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminEmailVerificationPage(
          email: state.adminUser.email,
          name: state.adminUser.name,
          employeeCode: state.adminUser.employeeCode,
          password: state.password,
          onNavigateToLogin: widget.onNavigateToLogin,
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(
    BuildContext context,
    String errorMessage,
  ) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          elevation: 0,
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusAnimationWidget(
                  type: StatusAnimationType.error,
                  size: 96,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pendaftaran Gagal',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'Tutup & Perbaiki',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<AdminAuthBloc, AdminAuthState>(
        listener: (context, state) {
          if (state is AdminAuthSuccess) {
            _navigateToVerification(context, state);
          } else if (state is AdminAuthFailure) {
            _showErrorDialog(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Latar belakang dekoratif subtle circle gradient
              Positioned(
                top: -120,
                right: -100,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary700.withValues(
                          alpha: isDark ? 0.12 : 0.06,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Konten Utama Registrasi (Tampilan Terpusat Bersih)
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 40 : 24,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 700 : 540,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.06,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isDesktop ? 36 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AdminRegisterHeader(),
                        const SizedBox(height: 24),
                        AdminRegisterCard(
                          onLoginPressed: () => _navigateToLogin(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
