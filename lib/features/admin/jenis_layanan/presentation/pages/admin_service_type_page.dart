import 'dart:async';
import 'dart:ui';

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
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/admin/payment/presentation/pages/admin_payment_page.dart';
import 'package:satset/features/admin/report/presentation/pages/admin_report_page.dart';
import 'package:satset/features/admin/settings/presentation/pages/admin_settings_page.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_service_type_remote_datasource.dart';
import '../../data/repositories/admin_service_type_repository_impl.dart';
import '../../domain/entities/admin_service_type_item.dart';
import '../bloc/admin_service_type_bloc.dart';
import '../bloc/admin_service_type_event.dart';
import '../bloc/admin_service_type_state.dart';
import '../widgets/service_type_data_table.dart';
import '../widgets/service_type_detail_dialog.dart';
import '../widgets/service_type_form_dialog.dart';
import '../widgets/service_type_skeleton.dart';
import '../widgets/service_type_summary_cards.dart';

class AdminServiceTypePage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminServiceTypePage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminServiceTypeRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminServiceTypeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminServiceTypeBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminServiceTypeStarted()),
      child: AdminServiceTypeView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminServiceTypeView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminServiceTypeView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminServiceTypeView> createState() => _AdminServiceTypeViewState();
}

class _AdminServiceTypeViewState extends State<AdminServiceTypeView> {
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
    if (route == '/admin/services') return;
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
    } else if (route == '/admin/settings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminSettingsPage(
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

  void _openCreateServiceModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ServiceTypeFormDialog(
        onSubmit: ({
          required kode,
          required namaLayanan,
          required estimasiHariMin,
          required estimasiHariMax,
          deskripsi,
          baseTariffPerKg,
          required isActive,
        }) {
          context.read<AdminServiceTypeBloc>().add(
                AdminServiceTypeCreateRequested(
                  kode: kode,
                  namaLayanan: namaLayanan,
                  estimasiHariMin: estimasiHariMin,
                  estimasiHariMax: estimasiHariMax,
                  deskripsi: deskripsi,
                  baseTariffPerKg: baseTariffPerKg,
                  isActive: isActive,
                ),
              );
        },
      ),
    );
  }

  void _openEditServiceModal(
    BuildContext context,
    AdminServiceTypeItem service,
  ) {
    showDialog(
      context: context,
      builder: (_) => ServiceTypeFormDialog(
        existingService: service,
        onSubmit: ({
          required kode,
          required namaLayanan,
          required estimasiHariMin,
          required estimasiHariMax,
          deskripsi,
          baseTariffPerKg,
          required isActive,
        }) {
          context.read<AdminServiceTypeBloc>().add(
                AdminServiceTypeUpdateRequested(
                  serviceId: service.id,
                  kode: kode,
                  namaLayanan: namaLayanan,
                  estimasiHariMin: estimasiHariMin,
                  estimasiHariMax: estimasiHariMax,
                  deskripsi: deskripsi,
                  baseTariffPerKg: baseTariffPerKg,
                  isActive: isActive,
                ),
              );
        },
      ),
    );
  }

  Future<void> _confirmToggleStatus(
    BuildContext context,
    AdminServiceTypeItem service,
  ) async {
    final targetActive = !service.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          targetActive
              ? 'Aktifkan Jenis Layanan?'
              : 'Nonaktifkan Jenis Layanan?',
        ),
        content: Text(
          targetActive
              ? 'Apakah Anda yakin ingin mengaktifkan kembali layanan "${service.namaLayanan}" (${service.kode})? Layanan akan tampil kembali pada formulir pemesanan pengiriman customer.'
              : 'Apakah Anda yakin ingin menonaktifkan layanan "${service.namaLayanan}" (${service.kode})? Customer tidak dapat memilih layanan ini untuk pesanan baru, sementara ${service.totalShipmentsCount} data pengiriman lama pada t_shipments tetap aman dan terjaga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  targetActive ? AppColors.success : AppColors.warning,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(targetActive ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminServiceTypeBloc>().add(
            AdminServiceTypeToggleStatusRequested(
              serviceId: service.id,
              isActive: targetActive,
            ),
          );
    }
  }

  Future<void> _confirmDeleteService(
    BuildContext context,
    AdminServiceTypeItem service,
  ) async {
    // Jika layanan sudah pernah digunakan pada t_shipments, arahkan untuk menonaktifkan layanan
    if (service.isUsedInShipments) {
      final deactivateInstead = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text('Layanan Memiliki Relasi Transaksi Pengiriman'),
              ),
            ],
          ),
          content: Text(
            'Jenis layanan "${service.namaLayanan}" (${service.kode}) sudah digunakan pada ${service.totalShipmentsCount} transaksi pengiriman di tabel t_shipments.\n\nSesuai aturan integritas database SatSet, layanan yang memiliki histori pengiriman tidak boleh dihapus agar referensi transaksi lama tidak rusak. Apakah Anda ingin menonaktifkan layanan ini agar tidak muncul pada pesanan baru?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Tutup'),
            ),
            if (service.isActive)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Nonaktifkan Layanan Saja'),
              ),
          ],
        ),
      );

      if (deactivateInstead == true && context.mounted) {
        context.read<AdminServiceTypeBloc>().add(
              AdminServiceTypeToggleStatusRequested(
                serviceId: service.id,
                isActive: false,
              ),
            );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(child: Text('Hapus Jenis Layanan?')),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus jenis layanan "${service.namaLayanan}" (${service.kode}) dari m_service_types? Layanan ini belum pernah digunakan pada transaksi pengiriman (0 relasi di t_shipments).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context
          .read<AdminServiceTypeBloc>()
          .add(AdminServiceTypeDeleteRequested(service.id));
    }
  }

  void _openDetailDialog(BuildContext context) {
    if (_isDetailDialogOpen) return;
    _isDetailDialogOpen = true;

    final bloc = context.read<AdminServiceTypeBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminServiceTypeBloc, AdminServiceTypeState>(
            builder: (ctx, state) {
              if (state.selectedDetail == null) {
                return const SizedBox.shrink();
              }
              return ServiceTypeDetailDialog(
                detail: state.selectedDetail!,
                isActionInProgress: state.isActionInProgress,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onEditService: (service) {
                  _openEditServiceModal(context, service);
                },
                onToggleStatus: (service) {
                  _confirmToggleStatus(context, service);
                },
                onDeleteService: (service) {
                  _confirmDeleteService(context, service);
                },
                onOpenDeliveryPage: () {
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
            .read<AdminServiceTypeBloc>()
            .add(const AdminServiceTypeDetailDismissed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminServiceTypeBloc, AdminServiceTypeState>(
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
              .read<AdminServiceTypeBloc>()
              .add(const AdminServiceTypeClearNotification());
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
              .read<AdminServiceTypeBloc>()
              .add(const AdminServiceTypeClearNotification());
        }
      },
      builder: (context, state) {
        if (state.status == AdminServiceTypeStatus.unauthorized) {
          return _buildUnauthorizedView(context, isDark, state.errorMessage);
        }

        if (state.status == AdminServiceTypeStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/services',
            onNavigate: (route) => _handleSidebarNavigation(context, route),
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
                sectionTitle: 'Portal Utama',
                pageTitle: 'Manajemen Jenis Layanan (Service Types)',
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
              const Expanded(child: AdminServiceTypeSkeleton()),
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

        if (state.status == AdminServiceTypeStatus.error) {
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
                      'Gagal Memuat Data Jenis Layanan',
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
                            .read<AdminServiceTypeBloc>()
                            .add(const AdminServiceTypeStarted());
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
          activeRoute: '/admin/services',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            AdminTopHeader(
              currentUser: widget.currentUser,
              sectionTitle: 'Portal Utama',
              pageTitle: 'Manajemen Jenis Layanan (Service Types)',
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context
                    .read<AdminServiceTypeBloc>()
                    .add(const AdminServiceTypeRefreshed());
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
                        .read<AdminServiceTypeBloc>()
                        .add(const AdminServiceTypeRefreshed());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Banner Manajemen Jenis Layanan
                        _buildHeaderBanner(),
                        const SizedBox(height: 20),

                        // 2. Ringkasan Statistik Aktual (m_service_types & relasi t_shipments)
                        ServiceTypeSummaryCards(
                          stats: state.servicesResult.summaryStats,
                          activeFilter: state.statusFilter,
                          onQuickFilterSelected: (filter) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypeFilterChanged(filter));
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. Container Terpadu: Header + Tombol Tambah Layanan + Filter Bar + Tabel
                        ServiceTypeDataTable(
                          servicesResult: state.servicesResult,
                          isLoading: state.isTableLoading,
                          isActionInProgress: state.isActionInProgress,
                          searchQuery: state.searchQuery,
                          statusFilter: state.statusFilter,
                          sortColumn: state.sortColumn,
                          sortAscending: state.sortAscending,
                          onSearchChanged: (query) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypeSearchChanged(query));
                          },
                          onFilterChanged: (filter) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypeFilterChanged(filter));
                          },
                          onSortChanged: (col) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypeSortChanged(col));
                          },
                          onResetFilters: () {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(const AdminServiceTypeFiltersReset());
                          },
                          onAddServicePressed: () =>
                              _openCreateServiceModal(context),
                          onPageChanged: (page) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypePageChanged(page));
                          },
                          onViewDetail: (serviceId) {
                            context
                                .read<AdminServiceTypeBloc>()
                                .add(AdminServiceTypeDetailRequested(serviceId));
                          },
                          onEditService: (service) {
                            _openEditServiceModal(context, service);
                          },
                          onToggleStatus: (service) {
                            _confirmToggleStatus(context, service);
                          },
                          onDeleteService: (service) {
                            _confirmDeleteService(context, service);
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
                  'Pusat Manajemen Jenis Layanan Pengiriman (m_service_types)',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola master jenis layanan pengiriman yang dipilih customer saat membuat pesanan, atur estimasi waktu pengiriman (SLA), tinjau aturan perhitungan tarif & asuransi, serta lindungi relasi historis pada t_shipments.',
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
              Icons.inventory_2_rounded,
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

