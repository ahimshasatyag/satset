import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/admin/admin_courier/presentation/pages/admin_courier_page.dart';
import 'package:satset/features/admin/admin_customer/presentation/pages/admin_customer_page.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/utils/admin_cookie_manager.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:satset/features/admin/delivery/presentation/pages/admin_delivery_page.dart';
import 'package:satset/features/admin/jenis_layanan/presentation/pages/admin_service_type_page.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/admin/payment/presentation/pages/admin_payment_page.dart';
import 'package:satset/features/admin/report/presentation/pages/admin_report_page.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_settings_remote_datasource.dart';
import '../../data/repositories/admin_settings_repository_impl.dart';
import '../bloc/admin_settings_bloc.dart';
import '../bloc/admin_settings_event.dart';
import '../bloc/admin_settings_state.dart';
import '../widgets/account_security_section.dart';
import '../widgets/admin_profile_section.dart';
import '../widgets/company_profile_section.dart';
import '../widgets/notification_preferences_section.dart';
import '../widgets/operational_settings_section.dart';
import '../widgets/settings_skeleton.dart';
import '../widgets/settings_tab_navigation.dart';
import '../widgets/system_info_section.dart';

class AdminSettingsPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminSettingsPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminSettingsRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminSettingsRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminSettingsBloc(
        repository: repository,
      )..add(const AdminSettingsStarted()),
      child: AdminSettingsView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminSettingsView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminSettingsView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cookieWatcherTimer;
  bool? _isAutoLoggingOut;
  bool? _isSidebarOpen;

  bool get _sidebarOpen => _isSidebarOpen ?? true;
  bool get _autoLoggingOut => _isAutoLoggingOut ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AdminCookieManager.hasAuthTokenCookie()) {
        _handleAutoLogoutOnMissingCookie();
      }
    });

    _cookieWatcherTimer = AdminCookieManager.startCookieWatcher(
      onCookieMissing: _handleAutoLogoutOnMissingCookie,
    );
  }

  @override
  void dispose() {
    _cookieWatcherTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleAutoLogoutOnMissingCookie() async {
    if (_autoLoggingOut || !mounted) return;
    _isAutoLoggingOut = true;
    _cookieWatcherTimer?.cancel();

    final localDataSource = AdminAuthLocalDataSourceImpl();
    await localDataSource.deleteAdmin();

    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;
    widget.onLogout?.call();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri sesi Administrator saat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _isAutoLoggingOut = true;
    _cookieWatcherTimer?.cancel();

    final localDataSource = AdminAuthLocalDataSourceImpl();
    await localDataSource.deleteAdmin();

    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    widget.onLogout?.call();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (route) => false,
      );
    }
  }

  void _handleSidebarNavigation(BuildContext context, String route) {
    if (route == '/admin/settings') return;
    if (route == '/admin/dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/shipments') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDeliveryPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/couriers') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminCourierPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/customers') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminCustomerPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/payments') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminPaymentPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/services') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminServiceTypePage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else if (route == '/admin/reports') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminReportPage(
            user: widget.currentUser,
            token: widget.token,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigasi menuju $route'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminSettingsBloc, AdminSettingsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AdminSettingsBloc>().add(
            const AdminSettingsClearFeedback(),
          );
        }
        if (state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AdminSettingsBloc>().add(
            const AdminSettingsClearFeedback(),
          );
        }
      },
      builder: (context, state) {
        if (state.status == AdminSettingsStatus.unauthorized) {
          return _buildUnauthorizedScreen(context, state.errorMessage);
        }

        final sidebar = AdminSidebar(
          activeRoute: '/admin/settings',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final topHeader = AdminTopHeader(
          currentUser: widget.currentUser,
          isRefreshing:
              state.isRefreshing || state.status == AdminSettingsStatus.loading,
          onRefresh: () {
            context.read<AdminSettingsBloc>().add(
              const AdminSettingsRefreshed(),
            );
          },
          showDrawerButton: true,
          isSidebarOpen: isDesktop ? _sidebarOpen : false,
          onOpenDrawer: () {
            if (isDesktop) {
              setState(() {
                _isSidebarOpen = !_sidebarOpen;
              });
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          onLogout: () => _handleLogout(context),
        );

        Widget bodyContent;
        if (state.status == AdminSettingsStatus.loading ||
            state.status == AdminSettingsStatus.initial) {
          bodyContent = const AdminSettingsSkeleton();
        } else if (state.status == AdminSettingsStatus.error) {
          bodyContent = _buildErrorScreen(context, state.errorMessage);
        } else if (state.settingsData != null) {
          final data = state.settingsData!;

          Widget activeSection;
          switch (state.activeTabIndex) {
            case 1:
              activeSection = CompanyProfileSection(
                companyProfile: data.companyProfile,
                isSaving: state.isSaving,
                onSaveCompany: (updated) {
                  context.read<AdminSettingsBloc>().add(
                    AdminSettingsCompanyUpdateRequested(updated),
                  );
                },
              );
              break;
            case 2:
              activeSection = OperationalSettingsSection(
                settings: data.operationalSettings,
                onToggleServiceStatus: (serviceId, isActive) {
                  context.read<AdminSettingsBloc>().add(
                    AdminSettingsServiceTypeToggled(
                      serviceTypeId: serviceId,
                      isActive: isActive,
                    ),
                  );
                },
              );
              break;
            case 3:
              activeSection = NotificationPreferencesSection(
                preferences: data.notificationPreferences,
                isSaving: state.isSaving,
                onSavePreferences: (updated) {
                  context.read<AdminSettingsBloc>().add(
                    AdminSettingsNotificationPreferencesUpdated(updated),
                  );
                },
              );
              break;
            case 4:
              activeSection = AccountSecuritySection(
                profile: data.adminProfile,
                isSaving: state.isSaving,
                onChangePassword: ({
                  required currentPassword,
                  required newPassword,
                  required confirmPassword,
                }) {
                  context.read<AdminSettingsBloc>().add(
                    AdminSettingsPasswordChangeRequested(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                      confirmPassword: confirmPassword,
                    ),
                  );
                },
                onLogout: () => _handleLogout(context),
              );
              break;
            case 5:
              activeSection = SystemInfoSection(
                systemInfo: data.systemInfo,
                onRefreshDiagnostics: () {
                  context.read<AdminSettingsBloc>().add(
                    const AdminSettingsRefreshed(),
                  );
                },
              );
              break;
            case 0:
            default:
              activeSection = AdminProfileSection(
                profile: data.adminProfile,
                isSaving: state.isSaving,
                onSaveProfile: ({
                  required adminId,
                  required namaLengkap,
                  required email,
                  required noHp,
                  alamatLengkap,
                }) {
                  context.read<AdminSettingsBloc>().add(
                    AdminSettingsProfileUpdateRequested(
                      adminId: adminId,
                      namaLengkap: namaLengkap,
                      email: email,
                      noHp: noHp,
                      alamatLengkap: alamatLengkap,
                    ),
                  );
                },
              );
              break;
          }

          bodyContent = Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Title
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pusat Pengaturan & Konfigurasi Sistem SatSet Delivery',
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pengaturan akun admin, profil perusahaan, operasional pengiriman, notifikasi, keamanan sandi, dan status sistem.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Navigation Tabs
                    SettingsTabNavigation(
                      activeIndex: state.activeTabIndex,
                      onTabSelected: (idx) {
                        context.read<AdminSettingsBloc>().add(
                          AdminSettingsTabChanged(idx),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Active Section Content
                    activeSection,
                  ],
                ),
              ),
              if (state.isRefreshing || state.isSaving)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        } else {
          bodyContent = const SizedBox.shrink();
        }

        final mainColumn = Column(
          children: [
            topHeader,
            Expanded(child: bodyContent),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Row(
              children: [
                if (_sidebarOpen) sidebar,
                Expanded(child: mainColumn),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: Drawer(child: sidebar),
            body: mainColumn,
          );
        }
      },
    );
  }

  Widget _buildUnauthorizedScreen(BuildContext context, String? message) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_outlined, size: 54),
              const SizedBox(height: 16),
              Text(
                'Akses Ditolak (403)',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Halaman Pengaturan hanya diizinkan untuk Administrator resmi (m_employee.id_users_role = 1).',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _handleLogout(context),
                child: const Text('Kembali ke Halaman Login Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String? message) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: 14),
            Text(
              'Gagal Memuat Pengaturan',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Terjadi kendala saat mengambil data konfigurasi dari database Supabase.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<AdminSettingsBloc>().add(
                  const AdminSettingsStarted(),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}

