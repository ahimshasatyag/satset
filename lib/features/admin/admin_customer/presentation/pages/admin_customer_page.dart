import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/admin/admin_courier/presentation/pages/admin_courier_page.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/utils/admin_cookie_manager.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:satset/features/admin/delivery/presentation/pages/admin_delivery_page.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_customer_remote_datasource.dart';
import '../../data/repositories/admin_customer_repository_impl.dart';
import '../../domain/entities/admin_customer_item.dart';
import '../../domain/repositories/admin_customer_repository.dart';
import '../bloc/admin_customer_bloc.dart';
import '../bloc/admin_customer_event.dart';
import '../bloc/admin_customer_state.dart';
import '../widgets/customer_data_table.dart';
import '../widgets/customer_detail_dialog.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customer_skeleton.dart';
import '../widgets/customer_summary_cards.dart';

class AdminCustomerPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminCustomerPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminCustomerRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminCustomerRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminCustomerBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminCustomerStarted()),
      child: AdminCustomerView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
        repository: repository,
      ),
    );
  }
}

class AdminCustomerView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;
  final AdminCustomerRepository repository;

  const AdminCustomerView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
    required this.repository,
  });

  @override
  State<AdminCustomerView> createState() => _AdminCustomerViewState();
}

class _AdminCustomerViewState extends State<AdminCustomerView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cookieWatcherTimer;
  bool? _isAutoLoggingOut;
  bool? _isSidebarOpen;
  bool _isDetailDialogOpen = false;

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

    widget.onLogout?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi berakhir otomatis karena Auth Token Cookie tidak ditemukan atau telah kadaluarsa.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Keluar dari Akun Admin?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri sesi Administrator saat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
        MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
        ),
        (route) => false,
      );
    }
  }

  void _handleSidebarNavigation(BuildContext context, String route) {
    if (route == '/admin/customers') return;
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

  void _openEditCustomerModal(
    BuildContext context,
    AdminCustomerItem customer,
  ) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(
        customer: customer,
        repository: widget.repository,
        onSubmit: ({
          required namaLengkap,
          required email,
          required noHp,
          alamatLengkap,
          idProvinsi,
          idKabkot,
          idKecamatan,
          idKelurahan,
          latitude,
          longitude,
          required emailVerified,
        }) {
          context.read<AdminCustomerBloc>().add(
                AdminCustomerUpdateRequested(
                  customerId: customer.id,
                  namaLengkap: namaLengkap,
                  email: email,
                  noHp: noHp,
                  alamatLengkap: alamatLengkap,
                  idProvinsi: idProvinsi,
                  idKabkot: idKabkot,
                  idKecamatan: idKecamatan,
                  idKelurahan: idKelurahan,
                  latitude: latitude,
                  longitude: longitude,
                  emailVerified: emailVerified,
                ),
              );
        },
      ),
    );
  }

  Future<void> _confirmToggleVerification(
    BuildContext context,
    AdminCustomerItem customer,
  ) async {
    final targetVerified = !customer.emailVerified;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          targetVerified
              ? 'Verifikasi Email Customer?'
              : 'Batalkan Verifikasi Email?',
        ),
        content: Text(
          targetVerified
              ? 'Apakah Anda yakin ingin menandai email customer "${customer.namaLengkap}" (${customer.email}) sebagai Terverifikasi (email_verified = true)?'
              : 'Apakah Anda yakin ingin membatalkan status verifikasi email customer "${customer.namaLengkap}" (${customer.email}) menjadi Belum Terverifikasi (email_verified = false)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  targetVerified ? AppColors.success : AppColors.warning,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              targetVerified ? 'Tandai Terverifikasi' : 'Batalkan Verifikasi',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminCustomerBloc>().add(
            AdminCustomerToggleVerificationRequested(
              customerId: customer.id,
              emailVerified: targetVerified,
            ),
          );
    }
  }

  void _openDetailDialog(BuildContext context) {
    if (_isDetailDialogOpen) return;
    _isDetailDialogOpen = true;

    final bloc = context.read<AdminCustomerBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminCustomerBloc, AdminCustomerState>(
            builder: (ctx, state) {
              if (state.selectedDetail == null) {
                return const SizedBox.shrink();
              }
              return CustomerDetailDialog(
                detail: state.selectedDetail!,
                isActionInProgress: state.isActionInProgress,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onEditProfile: (customer) {
                  _openEditCustomerModal(context, customer);
                },
                onToggleVerification: (customer) {
                  _confirmToggleVerification(context, customer);
                },
                onOpenDeliveryPage: (_) {
                  Navigator.of(dialogCtx).pop();
                  _handleSidebarNavigation(context, '/admin/shipments');
                },
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _isDetailDialogOpen = false;
      if (context.mounted) {
        context
            .read<AdminCustomerBloc>()
            .add(const AdminCustomerDetailDismissed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminCustomerBloc, AdminCustomerState>(
      listener: (context, state) {
        if (state.selectedDetail != null &&
            !state.isDetailLoading &&
            !_isDetailDialogOpen) {
          _openDetailDialog(context);
        }

        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context
              .read<AdminCustomerBloc>()
              .add(const AdminCustomerClearNotification());
        }

        if (state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context
              .read<AdminCustomerBloc>()
              .add(const AdminCustomerClearNotification());
        }
      },
      builder: (context, state) {
        if (state.status == AdminCustomerStatus.unauthorized) {
          return _buildUnauthorizedView(context, isDark, state.errorMessage);
        }

        if (state.status == AdminCustomerStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/customers',
            onNavigate: (route) => _handleSidebarNavigation(context, route),
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
                sectionTitle: 'Portal Utama',
                pageTitle: 'Manajemen Pelanggan SatSet (Customer Management)',
                isRefreshing: true,
                onRefresh: () {},
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
              ),
              const Expanded(child: AdminCustomerSkeleton()),
            ],
          );

          if (isDesktop) {
            return Scaffold(
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              body: Row(
                children: [
                  if (_sidebarOpen) loadingSidebar,
                  Expanded(child: loadingContent),
                ],
              ),
            );
          } else {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              drawer: Drawer(child: loadingSidebar),
              body: loadingContent,
            );
          }
        }

        if (state.status == AdminCustomerStatus.error) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Data Customer',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ??
                          'Terjadi gangguan koneksi ke database Supabase.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context
                            .read<AdminCustomerBloc>()
                            .add(const AdminCustomerStarted());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sidebar = AdminSidebar(
          activeRoute: '/admin/customers',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            AdminTopHeader(
              currentUser: widget.currentUser,
              sectionTitle: 'Portal Utama',
              pageTitle: 'Manajemen Pelanggan SatSet (Customer Management)',
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context
                    .read<AdminCustomerBloc>()
                    .add(const AdminCustomerRefreshed());
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
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<AdminCustomerBloc>()
                        .add(const AdminCustomerRefreshed());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Banner Manajemen Pelanggan
                        _buildHeaderBanner(),
                        const SizedBox(height: 20),

                        // 2. Ringkasan Statistik Jumlah Customer Aktual (m_users)
                        CustomerSummaryCards(
                          stats: state.customersResult.summaryStats,
                          activeVerificationFilter: state.verificationFilter,
                          onQuickFilterSelected: (filter) {
                            context.read<AdminCustomerBloc>().add(
                                  AdminCustomerFiltersUpdated(
                                    verificationFilter: filter,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. Container Terpadu: Header + Filter Bar + Tabel Daftar Customer (m_users)
                        CustomerDataTable(
                          customersResult: state.customersResult,
                          isLoading: state.isTableLoading,
                          isActionInProgress: state.isActionInProgress,
                          searchQuery: state.searchQuery,
                          verificationFilter: state.verificationFilter,
                          startDate: state.startDate,
                          endDate: state.endDate,
                          sortColumn: state.sortColumn,
                          sortAscending: state.sortAscending,
                          onSearchChanged: (query) {
                            context
                                .read<AdminCustomerBloc>()
                                .add(AdminCustomerSearchChanged(query));
                          },
                          onFiltersChanged: ({
                            verificationFilter,
                            startDate,
                            endDate,
                            clearDates = false,
                          }) {
                            context.read<AdminCustomerBloc>().add(
                                  AdminCustomerFiltersUpdated(
                                    verificationFilter: verificationFilter,
                                    startDate: startDate,
                                    endDate: endDate,
                                    clearDates: clearDates,
                                  ),
                                );
                          },
                          onSortChanged: (col) {
                            context
                                .read<AdminCustomerBloc>()
                                .add(AdminCustomerSortChanged(col));
                          },
                          onResetFilters: () {
                            context
                                .read<AdminCustomerBloc>()
                                .add(const AdminCustomerFiltersReset());
                          },
                          onPageChanged: (page) {
                            context
                                .read<AdminCustomerBloc>()
                                .add(AdminCustomerPageChanged(page));
                          },
                          onViewDetail: (customerId) {
                            context
                                .read<AdminCustomerBloc>()
                                .add(AdminCustomerDetailRequested(customerId));
                          },
                          onEditCustomer: (customer) {
                            _openEditCustomerModal(context, customer);
                          },
                          onToggleVerification: (customer) {
                            _confirmToggleVerification(context, customer);
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: Row(
              children: [
                if (_sidebarOpen) sidebar,
                Expanded(child: mainContent),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            drawer: Drawer(child: sidebar),
            body: mainContent,
          );
        }
      },
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pusat Manajemen Pelanggan SatSet (Customer Management)',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola seluruh profil customer terdaftar pada tabel m_users (id_users_role = 3), periksa hierarki alamat wilayah (m_provinsi, m_kabkot, m_kecamatan, m_kelurahan), tinjau daftar alamat tambahan m_address, serta pantau riwayat pengiriman t_shipments tanpa mengekspos kata sandi akun.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: AppColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedView(
    BuildContext context,
    bool isDark,
    String? message,
  ) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                size: 54,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Akses Khusus Administrator',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Halaman ini hanya dapat diakses oleh Administrator resmi (m_employee.id_users_role = 1).',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _handleLogout(context),
                child: const Text('Keluar & Ganti Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

