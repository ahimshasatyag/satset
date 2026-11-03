import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/utils/admin_cookie_manager.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/admin_customer/presentation/pages/admin_customer_page.dart';
import 'package:satset/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:satset/features/admin/delivery/presentation/pages/admin_delivery_page.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_courier_remote_datasource.dart';
import '../../data/repositories/admin_courier_repository_impl.dart';
import '../../domain/entities/admin_courier_item.dart';
import '../bloc/admin_courier_bloc.dart';
import '../bloc/admin_courier_event.dart';
import '../bloc/admin_courier_state.dart';
import '../widgets/courier_data_table.dart';
import '../widgets/courier_detail_dialog.dart';
import '../widgets/courier_form_dialog.dart';
import '../widgets/courier_skeleton.dart';
import '../widgets/courier_summary_cards.dart';

class AdminCourierPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminCourierPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminCourierRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminCourierRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminCourierBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminCourierStarted()),
      child: AdminCourierView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminCourierView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminCourierView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminCourierView> createState() => _AdminCourierViewState();
}

class _AdminCourierViewState extends State<AdminCourierView> {
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
    if (route == '/admin/couriers') return;
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

  void _openCreateCourierModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CourierFormDialog(
        onSubmit: ({
          required namaLengkap,
          required email,
          required noHp,
          password,
          employeeCode,
          alamatLengkap,
          fotoUrl,
          required isActive,
        }) {
          context.read<AdminCourierBloc>().add(
                AdminCourierCreateRequested(
                  namaLengkap: namaLengkap,
                  email: email,
                  noHp: noHp,
                  password: password ?? '',
                  employeeCode: employeeCode,
                  alamatLengkap: alamatLengkap,
                  fotoUrl: fotoUrl,
                  isActive: isActive,
                ),
              );
        },
      ),
    );
  }

  void _openEditCourierModal(BuildContext context, AdminCourierItem courier) {
    showDialog(
      context: context,
      builder: (_) => CourierFormDialog(
        existingCourier: courier,
        onSubmit: ({
          required namaLengkap,
          required email,
          required noHp,
          password,
          employeeCode,
          alamatLengkap,
          fotoUrl,
          required isActive,
        }) {
          context.read<AdminCourierBloc>().add(
                AdminCourierUpdateRequested(
                  courierId: courier.id,
                  namaLengkap: namaLengkap,
                  email: email,
                  noHp: noHp,
                  alamatLengkap: alamatLengkap,
                  fotoUrl: fotoUrl,
                  newPassword: password,
                  isActive: isActive,
                ),
              );
        },
      ),
    );
  }

  Future<void> _confirmToggleStatus(
    BuildContext context,
    AdminCourierItem courier,
  ) async {
    final targetActive = !courier.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          targetActive ? 'Aktifkan Akun Kurir?' : 'Nonaktifkan Akun Kurir?',
        ),
        content: Text(
          targetActive
              ? 'Apakah Anda yakin ingin mengaktifkan kembali akun kurir "${courier.namaLengkap}" (${courier.employeeCode})? Kurir akan dapat menerima tugas pengiriman baru.'
              : 'Apakah Anda yakin ingin menonaktifkan akun kurir "${courier.namaLengkap}" (${courier.employeeCode})? Kurir tidak akan muncul dalam daftar penugasan baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  targetActive ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(targetActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminCourierBloc>().add(
            AdminCourierToggleStatusRequested(
              courierId: courier.id,
              isActive: targetActive,
            ),
          );
    }
  }

  Future<void> _confirmUnassignTask(
    BuildContext context,
    int assignmentId,
    int shipmentId,
    String nomorResi,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lepas Penugasan Kurir'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apakah Anda yakin ingin melepas penugasan pengiriman $nomorResi dari kurir ini? Tindakan ini akan dicatat pada t_shipment_assignments dan t_shipment_tracking.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alasan Pelepasan Penugasan (Opsional)',
                  hintText: 'Contoh: Beban kerja kurir penuh / dialihkan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lepas Penugasan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      context.read<AdminCourierBloc>().add(
            AdminCourierUnassignTaskRequested(
              assignmentId: assignmentId,
              shipmentId: shipmentId,
              reason: reason.isEmpty ? null : reason,
            ),
          );
    }
  }

  void _openDetailDialog(BuildContext context) {
    if (_isDetailDialogOpen) return;
    _isDetailDialogOpen = true;

    final bloc = context.read<AdminCourierBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminCourierBloc, AdminCourierState>(
            builder: (ctx, state) {
              if (state.selectedDetail == null) {
                return const SizedBox.shrink();
              }
              return CourierDetailDialog(
                detail: state.selectedDetail!,
                isActionInProgress: state.isActionInProgress,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onEditProfile: (courier) {
                  _openEditCourierModal(context, courier);
                },
                onToggleStatus: (courier) {
                  _confirmToggleStatus(context, courier);
                },
                onUnassignTask: (assignmentId, shipmentId, nomorResi) {
                  _confirmUnassignTask(
                    context,
                    assignmentId,
                    shipmentId,
                    nomorResi,
                  );
                },
                onInspectShipmentInDeliveryPage: (_) {
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
            .read<AdminCourierBloc>()
            .add(const AdminCourierDetailDismissed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminCourierBloc, AdminCourierState>(
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
              .read<AdminCourierBloc>()
              .add(const AdminCourierClearNotification());
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
              .read<AdminCourierBloc>()
              .add(const AdminCourierClearNotification());
        }
      },
      builder: (context, state) {
        if (state.status == AdminCourierStatus.unauthorized) {
          return _buildUnauthorizedView(context, isDark, state.errorMessage);
        }

        if (state.status == AdminCourierStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/couriers',
            onNavigate: (route) => _handleSidebarNavigation(context, route),
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
                sectionTitle: 'Portal Utama',
                pageTitle: 'Manajemen Kurir SatSet (Courier Management)',
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
              const Expanded(child: AdminCourierSkeleton()),
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

        if (state.status == AdminCourierStatus.error) {
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
                      'Gagal Memuat Data Kurir',
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
                            .read<AdminCourierBloc>()
                            .add(const AdminCourierStarted());
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
          activeRoute: '/admin/couriers',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            AdminTopHeader(
              currentUser: widget.currentUser,
              sectionTitle: 'Portal Utama',
              pageTitle: 'Manajemen Kurir SatSet (Courier Management)',
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context
                    .read<AdminCourierBloc>()
                    .add(const AdminCourierRefreshed());
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
                        .read<AdminCourierBloc>()
                        .add(const AdminCourierRefreshed());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Banner Manajemen Kurir
                        _buildHeaderBanner(),
                        const SizedBox(height: 20),

                        // 2. Ringkasan Statistik Jumlah Kurir Aktual
                        CourierSummaryCards(
                          stats: state.couriersResult.summaryStats,
                          activeAccountFilter: state.accountStatusFilter,
                          activeActivityFilter: state.activityStatusFilter,
                          onQuickFilterSelected: ({
                            accountStatusFilter,
                            activityStatusFilter,
                          }) {
                            context.read<AdminCourierBloc>().add(
                                  AdminCourierFiltersUpdated(
                                    accountStatusFilter: accountStatusFilter,
                                    activityStatusFilter: activityStatusFilter,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. Container Terpadu: Header + Tombol Tambah Kurir + Filter Bar + Tabel Daftar Kurir
                        CourierDataTable(
                          couriersResult: state.couriersResult,
                          isLoading: state.isTableLoading,
                          isActionInProgress: state.isActionInProgress,
                          searchQuery: state.searchQuery,
                          accountStatusFilter: state.accountStatusFilter,
                          activityStatusFilter: state.activityStatusFilter,
                          sortColumn: state.sortColumn,
                          sortAscending: state.sortAscending,
                          onSearchChanged: (query) {
                            context
                                .read<AdminCourierBloc>()
                                .add(AdminCourierSearchChanged(query));
                          },
                          onFiltersChanged: ({
                            accountStatusFilter,
                            activityStatusFilter,
                          }) {
                            context.read<AdminCourierBloc>().add(
                                  AdminCourierFiltersUpdated(
                                    accountStatusFilter: accountStatusFilter,
                                    activityStatusFilter: activityStatusFilter,
                                  ),
                                );
                          },
                          onSortChanged: (col) {
                            context
                                .read<AdminCourierBloc>()
                                .add(AdminCourierSortChanged(col));
                          },
                          onResetFilters: () {
                            context
                                .read<AdminCourierBloc>()
                                .add(const AdminCourierFiltersReset());
                          },
                          onAddCourierPressed: () =>
                              _openCreateCourierModal(context),
                          onPageChanged: (page) {
                            context
                                .read<AdminCourierBloc>()
                                .add(AdminCourierPageChanged(page));
                          },
                          onViewDetail: (courierId) {
                            context
                                .read<AdminCourierBloc>()
                                .add(AdminCourierDetailRequested(courierId));
                          },
                          onEditCourier: (courier) {
                            _openEditCourierModal(context, courier);
                          },
                          onToggleStatus: (courier) {
                            _confirmToggleStatus(context, courier);
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
                  'Pusat Manajemen Kurir SatSet (Courier Management)',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola seluruh akun kurir terdaftar (m_employee id_users_role = 2), pantau penugasan aktif pada t_shipment_assignments, lacak lokasi GPS terakhir pada t_shipment_locations, dan tinjau riwayat aktivitas t_shipment_tracking.',
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
              Icons.two_wheeler_rounded,
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

