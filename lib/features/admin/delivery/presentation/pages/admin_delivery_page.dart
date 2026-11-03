import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/utils/admin_cookie_manager.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/admin_courier/presentation/pages/admin_courier_page.dart';
import 'package:satset/features/admin/admin_customer/presentation/pages/admin_customer_page.dart';
import 'package:satset/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../data/datasources/admin_delivery_remote_datasource.dart';
import '../../data/repositories/admin_delivery_repository_impl.dart';
import '../../domain/entities/admin_delivery_item.dart';
import '../bloc/admin_delivery_bloc.dart';
import '../bloc/admin_delivery_event.dart';
import '../bloc/admin_delivery_state.dart';
import '../widgets/courier_assignment_dialog.dart';
import '../widgets/delivery_data_table.dart';
import '../widgets/delivery_detail_dialog.dart';
import '../widgets/delivery_filter_bar.dart';
import '../widgets/delivery_status_tabs.dart';
import '../widgets/delivery_skeleton.dart';

class AdminDeliveryPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminDeliveryPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminDeliveryRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminDeliveryRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminDeliveryBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminDeliveryStarted()),
      child: AdminDeliveryView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminDeliveryView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminDeliveryView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminDeliveryView> createState() => _AdminDeliveryViewState();
}

class _AdminDeliveryViewState extends State<AdminDeliveryView> {
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
    if (route == '/admin/shipments') return;
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

  Future<void> _confirmShipmentDialog(
    BuildContext context,
    int shipmentId,
    String nomorResi,
  ) async {
    final notesController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pesanan Pengiriman'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apakah Anda yakin ingin mengonfirmasi pesanan pengiriman $nomorResi? Status akan diperbarui menjadi CONFIRMED dan dicatat pada kronologi tracking.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Konfirmasi (Opsional)',
                  hintText: 'Contoh: Pesanan terverifikasi dan siap di-pickup...',
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Konfirmasi Pesanan'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final notes = notesController.text.trim();
      context.read<AdminDeliveryBloc>().add(
            AdminDeliveryConfirmOrderRequested(
              shipmentId: shipmentId,
              notes: notes.isEmpty ? null : notes,
            ),
          );
    }
  }

  void _openCourierAssignmentModal(
    BuildContext context,
    AdminDeliveryItem item,
    AdminDeliveryState state,
  ) {
    showDialog(
      context: context,
      builder: (_) => CourierAssignmentDialog(
        shipmentId: item.id,
        nomorResi: item.nomorResi,
        currentCourierId: item.courierId,
        currentCourierName: item.courierNama,
        couriers: state.couriers,
        onConfirmAssignment: (courierId, notes) {
          context.read<AdminDeliveryBloc>().add(
                AdminDeliveryAssignCourierRequested(
                  shipmentId: item.id,
                  courierId: courierId,
                  notes: notes,
                ),
              );
        },
      ),
    );
  }

  void _openDetailDialog(BuildContext context) {
    if (_isDetailDialogOpen) return;
    _isDetailDialogOpen = true;

    final bloc = context.read<AdminDeliveryBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminDeliveryBloc, AdminDeliveryState>(
            builder: (ctx, state) {
              if (state.selectedDetail == null) {
                return const SizedBox.shrink();
              }
              return DeliveryDetailDialog(
                detail: state.selectedDetail!,
                couriers: state.couriers,
                statusOptions: state.statusOptions,
                isActionInProgress: state.isActionInProgress,
                onClose: () {
                  Navigator.of(dialogCtx).pop();
                },
                onConfirmOrder: (notes) {
                  _confirmShipmentDialog(
                    context,
                    state.selectedDetail!.id,
                    state.selectedDetail!.nomorResi,
                  );
                },
                onAssignCourier: (courierId, notes) {
                  bloc.add(
                    AdminDeliveryAssignCourierRequested(
                      shipmentId: state.selectedDetail!.id,
                      courierId: courierId,
                      notes: notes,
                    ),
                  );
                },
                onUpdateStatus: (targetCode, lokasi, notes) {
                  bloc.add(
                    AdminDeliveryUpdateStatusRequested(
                      shipmentId: state.selectedDetail!.id,
                      targetStatusCode: targetCode,
                      lokasiNama: lokasi,
                      notes: notes,
                    ),
                  );
                },
                onHandleFailed: (action, reassignCourierId, notes) {
                  bloc.add(
                    AdminDeliveryHandleFailedRequested(
                      shipmentId: state.selectedDetail!.id,
                      resolutionAction: action,
                      reassignCourierId: reassignCourierId,
                      notes: notes,
                    ),
                  );
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
            .read<AdminDeliveryBloc>()
            .add(const AdminDeliveryDetailDismissed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminDeliveryBloc, AdminDeliveryState>(
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
              .read<AdminDeliveryBloc>()
              .add(const AdminDeliveryClearNotification());
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
              .read<AdminDeliveryBloc>()
              .add(const AdminDeliveryClearNotification());
        }
      },
      builder: (context, state) {
        if (state.status == AdminDeliveryStatus.unauthorized) {
          return _buildUnauthorizedView(context, isDark, state.errorMessage);
        }

        if (state.status == AdminDeliveryStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/shipments',
            onNavigate: (route) => _handleSidebarNavigation(context, route),
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
                sectionTitle: 'Portal Utama',
                pageTitle: 'Manajemen Pengiriman (Delivery)',
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
              const Expanded(child: AdminDeliverySkeleton()),
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

        if (state.status == AdminDeliveryStatus.error) {
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
                      'Gagal Memuat Data Pengiriman',
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
                            .read<AdminDeliveryBloc>()
                            .add(const AdminDeliveryStarted());
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
          activeRoute: '/admin/shipments',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            AdminTopHeader(
              currentUser: widget.currentUser,
              sectionTitle: 'Portal Utama',
              pageTitle: 'Manajemen Pengiriman (Delivery)',
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context
                    .read<AdminDeliveryBloc>()
                    .add(const AdminDeliveryRefreshed());
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
                        .read<AdminDeliveryBloc>()
                        .add(const AdminDeliveryRefreshed());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Banner Manajemen Pengiriman
                        _buildHeaderBanner(isDark),
                        const SizedBox(height: 20),

                        // 2. Ringkasan Jumlah & Tab Pengelompokan Status Pengiriman
                        DeliveryStatusTabs(
                          activeTab: state.activeTab,
                          tabCounts: state.deliveriesResult.tabCounts,
                          onTabSelected: (tabKey) {
                            context
                                .read<AdminDeliveryBloc>()
                                .add(AdminDeliveryTabChanged(tabKey));
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. Bar Pencarian & Filter Komprehensif
                        DeliveryFilterBar(
                          searchQuery: state.searchQuery,
                          statusFilter: state.statusFilter,
                          paymentMethodFilter: state.paymentMethodFilter,
                          paymentStatusFilter: state.paymentStatusFilter,
                          serviceFilter: state.serviceFilter,
                          courierFilter: state.courierFilter,
                          startDate: state.startDate,
                          endDate: state.endDate,
                          statusOptions: state.statusOptions,
                          serviceOptions: state.serviceOptions,
                          couriers: state.couriers,
                          onSearchChanged: (query) {
                            context
                                .read<AdminDeliveryBloc>()
                                .add(AdminDeliverySearchChanged(query));
                          },
                          onFiltersChanged: ({
                            statusFilter,
                            paymentMethodFilter,
                            paymentStatusFilter,
                            serviceFilter,
                            courierFilter,
                            startDate,
                            endDate,
                            clearDates = false,
                          }) {
                            context.read<AdminDeliveryBloc>().add(
                                  AdminDeliveryFiltersUpdated(
                                    statusFilter: statusFilter,
                                    paymentMethodFilter: paymentMethodFilter,
                                    paymentStatusFilter: paymentStatusFilter,
                                    serviceFilter: serviceFilter,
                                    courierFilter: courierFilter,
                                    startDate: startDate,
                                    endDate: endDate,
                                    clearDates: clearDates,
                                  ),
                                );
                          },
                          onResetFilters: () {
                            context
                                .read<AdminDeliveryBloc>()
                                .add(const AdminDeliveryFiltersReset());
                          },
                        ),
                        const SizedBox(height: 16),

                        // 4. Tabel Daftar Pengiriman + Tindakan Operasional
                        DeliveryDataTable(
                          deliveriesResult: state.deliveriesResult,
                          isLoading: state.isTableLoading,
                          isActionInProgress: state.isActionInProgress,
                          sortColumn: state.sortColumn,
                          sortAscending: state.sortAscending,
                          onSortChanged: (col) {
                            context
                                .read<AdminDeliveryBloc>()
                                .add(AdminDeliverySortChanged(col));
                          },
                          onPageChanged: (page) {
                            context
                                .read<AdminDeliveryBloc>()
                                .add(AdminDeliveryPageChanged(page));
                          },
                          onViewDetail: (shipmentId) {
                            context.read<AdminDeliveryBloc>().add(
                                  AdminDeliveryDetailRequested(shipmentId),
                                );
                          },
                          onConfirmOrder: (item) {
                            _confirmShipmentDialog(
                              context,
                              item.id,
                              item.nomorResi,
                            );
                          },
                          onAssignCourier: (item) {
                            _openCourierAssignmentModal(context, item, state);
                          },
                          onHandleFailed: (item) {
                            context.read<AdminDeliveryBloc>().add(
                                  AdminDeliveryDetailRequested(item.id),
                                );
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

  Widget _buildHeaderBanner(bool isDark) {
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
                  'Pusat Manajemen Pengiriman (Delivery Management)',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola konfirmasi pesanan customer, penugasan kurir (m_employee role 2), pelacakan kronologi t_shipment_tracking, dan penanganan kendala pengiriman secara real-time.',
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
              Icons.local_shipping_rounded,
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

