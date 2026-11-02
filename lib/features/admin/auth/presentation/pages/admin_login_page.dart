import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../data/datasources/admin_auth_local_datasource.dart';
import '../../data/datasources/admin_auth_remote_datasource.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_auth_repository_impl.dart';
import '../../data/utils/admin_cookie_manager.dart';
import '../../domain/usecases/admin_login_usecase.dart';
import '../../domain/usecases/admin_logout_usecase.dart';
import '../../domain/usecases/get_current_admin_usecase.dart';
import '../bloc/admin_auth_bloc.dart';
import '../bloc/admin_auth_event.dart';
import '../bloc/admin_auth_state.dart';
import '../widgets/admin_login_card.dart';
import '../widgets/admin_login_header.dart';

class AdminLoginPage extends StatelessWidget {
  final void Function(User user)? onLoginSuccess;

  const AdminLoginPage({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminAuthRemoteDataSourceImpl(client: SupabaseConfig.client);
    final localDataSource = AdminAuthLocalDataSourceImpl();
    final repository = AdminAuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final loginUseCase = AdminLoginUseCase(repository);
    final getCurrentAdminUseCase = GetCurrentAdminUseCase(repository);
    final logoutUseCase = AdminLogoutUseCase(repository);

    return BlocProvider(
      create: (context) => AdminAuthBloc(
        loginUseCase: loginUseCase,
        getCurrentAdminUseCase: getCurrentAdminUseCase,
        logoutUseCase: logoutUseCase,
        repository: repository,
      )..add(const AdminAuthCheckRequested()),
      child: AdminLoginView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class AdminLoginView extends StatefulWidget {
  final void Function(User user)? onLoginSuccess;

  const AdminLoginView({super.key, this.onLoginSuccess});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  @override
  void initState() {
    super.initState();
    // Daftarkan helper Console Browser untuk autentikasi menggunakan Auth Token Cookie
    AdminCookieManager.registerConsoleTokenHelper(
      onTokenLogin: _handleConsoleTokenLogin,
    );
  }

  Future<void> _handleConsoleTokenLogin(String token, String email) async {
    final adminModel = AdminUserModel(
      id: '1',
      employeeCode: 'ADM-001',
      name: 'Administrator SatSet',
      email: email,
      phone: '081234567890',
      role: 'admin',
      isActive: true,
      token: token,
    );

    final localDataSource = AdminAuthLocalDataSourceImpl();
    await localDataSource.saveAdmin(adminModel);

    final user = adminModel.toUser();

    if (!mounted) return;
    widget.onLoginSuccess?.call(user);

    try {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(user: user, token: token),
        ),
        (route) => false,
      );
    } catch (_) {}
  }

  void _handleSuccess(BuildContext context, AdminAuthSuccess state) {
    final user = state.adminUser.toUser();
    final activeToken = user.token ??
        state.adminUser.token ??
        'satset_admin_session_${DateTime.now().millisecondsSinceEpoch}';

    // Simpan Auth Token ke Browser Cookies
    AdminCookieManager.setAuthTokenCookie(
      token: activeToken,
      email: user.email,
      role: user.role,
    );

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(user);
    }
    // Langsung arahkan Navigator menuju AdminDashboardPage
    try {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(user: user, token: activeToken),
        ),
        (route) => false,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: BlocConsumer<AdminAuthBloc, AdminAuthState>(
        listener: (context, state) {
          if (state is AdminAuthSuccess) {
            _handleSuccess(context, state);
          }
        },
        builder: (context, state) {
          final savedEmail = state is AdminAuthUnauthenticated ? state.savedEmail : null;
          final rememberMe = state is AdminAuthUnauthenticated ? state.rememberMe : false;

          return Stack(
            children: [
              // Latar belakang dekoratif subtle mesh/gradient
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
                        AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Layout Konten Utama
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1040 : 500,
                    ),
                    child: isDesktop
                        ? _buildDesktopLayout(context, isDark, savedEmail, rememberMe)
                        : _buildMobileCard(context, isDark, savedEmail, rememberMe),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    String? savedEmail,
    bool rememberMe,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sisi Kiri: Showcase & Ilustrasi Portal Admin
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary800,
                    AppColors.primary,
                    AppColors.primary700,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Keamanan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'PORTAL ADMINISTRATOR',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'SatSet Delivery\nOperations Hub',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pusat monitoring terintegrasi untuk pengawasan paket real-time, performa kurir, penugasan armada, dan analitik pendapatan.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Fitur Poin Unggulan
                  _buildFeatureItem(
                    icon: Icons.track_changes_rounded,
                    title: 'Pelacakan Status Realtime',
                    desc: 'Sinkronisasi instan status resi dari Supabase Database.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.two_wheeler_rounded,
                    title: 'Monitoring Kurir Lapangan',
                    desc: 'Pantau kurir aktif dan penugasan pengiriman harian.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.insights_rounded,
                    title: 'Analitik & Rekapitulasi Keuangan',
                    desc: 'Grafik tren volume kiriman dan distribusi metode bayar.',
                  ),

                  const SizedBox(height: 32),
                  Text(
                    '© 2026 SatSet.id • All Rights Reserved',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sisi Kanan: Form Login
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AdminLoginHeader(),
                  const SizedBox(height: 28),
                  AdminLoginCard(
                    initialEmail: savedEmail,
                    initialRememberMe: rememberMe,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCard(
    BuildContext context,
    bool isDark,
    String? savedEmail,
    bool rememberMe,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminLoginHeader(),
          const SizedBox(height: 28),
          AdminLoginCard(
            initialEmail: savedEmail,
            initialRememberMe: rememberMe,
          ),
        ],
      ),
    );
  }
}

