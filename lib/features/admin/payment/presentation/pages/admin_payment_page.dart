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
import 'package:satset/features/admin/jenis_layanan/presentation/pages/admin_service_type_page.dart';
import 'package:satset/features/admin/report/presentation/pages/admin_report_page.dart';
import 'package:satset/features/admin/settings/presentation/pages/admin_settings_page.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_payment_remote_datasource.dart';
import '../../data/repositories/admin_payment_repository_impl.dart';
import '../../domain/entities/admin_payment_item.dart';
import '../bloc/admin_payment_bloc.dart';
import '../bloc/admin_payment_event.dart';
import '../bloc/admin_payment_state.dart';
import '../widgets/payment_charts_section.dart';
import '../widgets/payment_data_table.dart';
import '../widgets/payment_detail_dialog.dart';
import '../widgets/payment_export_dialog.dart';
import '../widgets/payment_skeleton.dart';
import '../widgets/payment_status_tabs.dart';
import '../widgets/payment_summary_cards.dart';

class AdminPaymentPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminPaymentPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminPaymentRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminPaymentRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminPaymentBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminPaymentStarted()),
      child: AdminPaymentView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminPaymentView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminPaymentView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminPaymentView> createState() => _AdminPaymentViewState();
}

class _AdminPaymentViewState extends State<AdminPaymentView> {
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
    if (route == '/admin/payments') return;
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

  Future<void> _confirmReconcilePayment(
    BuildContext context,
    AdminPaymentItem item,
  ) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sync_lock_rounded, color: AppColors.info),
            SizedBox(width: 10),
            Expanded(
              child: Text('Rekonsiliasi & Validasi Pembayaran'),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sistem akan memeriksa status pembayaran #${item.nomorPembayaran} (Resi: ${item.nomorResi}), memvalidasi kesesuaian nominal jumlah_bayar dengan total_biaya (${AdminCurrencyFormatter.formatRupiah(item.totalBiayaShipment)}), serta mengevaluasi batas waktu pembayaran secara idempoten melalui backend.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Audit Rekonsiliasi (Opsional)',
                  hintText: 'Contoh: Pengecekan berkala mutasi gateway...',
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
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.info),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Jalankan Rekonsiliasi'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminPaymentBloc>().add(
            AdminPaymentReconcileRequested(
              paymentId: item.id,
              shipmentId: item.shipmentId,
              notes: notesController.text.trim(),
            ),
          );
    }
  }

  Future<void> _confirmCodSettlement(
    BuildContext context,
    AdminPaymentItem item,
  ) async {
    final refController = TextEditingController(
      text: item.providerReference != null &&
              item.providerReference!.isNotEmpty &&
              item.providerReference != 'COD-PAY-ON-DELIVERY'
          ? item.providerReference
          : 'COD-SETTLED-${item.id}',
    );
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Expanded(
              child: Text('Verifikasi & Konfirmasi Setoran COD'),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Konfirmasi penerimaan dana Cash on Delivery (COD) untuk transaksi #${item.nomorPembayaran} (Resi: ${item.nomorResi}) sebesar ${AdminCurrencyFormatter.formatRupiah(item.totalBiayaShipment)}.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refController,
                decoration: InputDecoration(
                  labelText: 'Nomor Referensi / Bukti Setoran Kurir',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Verifikasi COD (Opsional)',
                  hintText: 'Contoh: Dana tunai diterima dari kurir...',
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
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.verified_rounded, size: 17),
            label: const Text('Konfirmasi COD Lunas'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminPaymentBloc>().add(
            AdminPaymentConfirmCodRequested(
              paymentId: item.id,
              shipmentId: item.shipmentId,
              verifiedAmount: item.totalBiayaShipment > 0
                  ? item.totalBiayaShipment
                  : item.jumlahBayar,
              settlementReference: refController.text.trim(),
              notes: notesController.text.trim(),
            ),
          );
    }
  }

  void _openDetailDialog(BuildContext context) {
    if (_isDetailDialogOpen) return;
    _isDetailDialogOpen = true;

    final bloc = context.read<AdminPaymentBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminPaymentBloc, AdminPaymentState>(
            builder: (ctx, state) {
              if (state.selectedDetail == null) {
                return const SizedBox.shrink();
              }
              return PaymentDetailDialog(
                detail: state.selectedDetail!,
                isActionInProgress: state.isActionInProgress,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onReconcilePayment: (item) {
                  _confirmReconcilePayment(context, item);
                },
                onConfirmCodPayment: (item) {
                  _confirmCodSettlement(context, item);
                },
                onOpenShipmentPage: () {
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
            .read<AdminPaymentBloc>()
            .add(const AdminPaymentDetailDismissed());
      }
    });
  }

  void _openExportDialog(
    BuildContext context,
    AdminPaymentsPaginatedResult paymentsResult,
  ) {
    showDialog(
      context: context,
      builder: (_) => PaymentExportDialog(
        paymentsResult: paymentsResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminPaymentBloc, AdminPaymentState>(
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
              .read<AdminPaymentBloc>()
              .add(const AdminPaymentClearNotification());
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
              .read<AdminPaymentBloc>()
              .add(const AdminPaymentClearNotification());
        }
      },
      builder: (context, state) {
        if (state.status == AdminPaymentStatus.unauthorized) {
          return _buildUnauthorizedView(context, isDark, state.errorMessage);
        }

        if (state.status == AdminPaymentStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/payments',
            onNavigate: (route) => _handleSidebarNavigation(context, route),
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
                sectionTitle: 'Portal Utama',
                pageTitle: 'Manajemen Pembayaran SatSet (Payment Management)',
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
              const Expanded(child: AdminPaymentSkeleton()),
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

        if (state.status == AdminPaymentStatus.error) {
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
                      'Gagal Memuat Data Pembayaran',
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
                            .read<AdminPaymentBloc>()
                            .add(const AdminPaymentStarted());
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
          activeRoute: '/admin/payments',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            AdminTopHeader(
              currentUser: widget.currentUser,
              sectionTitle: 'Portal Utama',
              pageTitle: 'Manajemen Pembayaran SatSet (Payment Management)',
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context
                    .read<AdminPaymentBloc>()
                    .add(const AdminPaymentRefreshed());
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
                        .read<AdminPaymentBloc>()
                        .add(const AdminPaymentRefreshed());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Banner Manajemen Pembayaran
                        _buildHeaderBanner(),
                        const SizedBox(height: 20),

                        // 2. Ringkasan Statistik Pembayaran Aktual (t_shipment_payments)
                        PaymentSummaryCards(
                          stats: state.paymentsResult.summaryStats,
                          activeTab: state.activeTab,
                          onTabSelected: (tab) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentTabSelected(tab));
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. Grafik Transaksi Pembayaran per Periode (Harian/Mingguan/Bulanan) & Distribusi Metode/Status
                        PaymentChartsSection(
                          stats: state.paymentsResult.summaryStats,
                          selectedPeriod: state.selectedPeriod,
                          onPeriodChanged: (period) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentPeriodChanged(period));
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Tab Pengelompokan Status & Metode Pembayaran
                        PaymentStatusTabs(
                          activeTab: state.activeTab,
                          tabCounts: state.paymentsResult.tabCounts,
                          onTabSelected: (tab) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentTabSelected(tab));
                          },
                        ),
                        const SizedBox(height: 16),

                        // 5. Container Terpadu: Header + Ekspor CSV + Filter Bar + Tabel Transaksi Pembayaran
                        PaymentDataTable(
                          paymentsResult: state.paymentsResult,
                          isLoading: state.isTableLoading,
                          isActionInProgress: state.isActionInProgress,
                          searchQuery: state.searchQuery,
                          methodFilter: state.methodFilter,
                          statusFilter: state.statusFilter,
                          jenisBankFilter: state.jenisBankFilter,
                          startDate: state.startDate,
                          endDate: state.endDate,
                          minAmount: state.minAmount,
                          maxAmount: state.maxAmount,
                          sortColumn: state.sortColumn,
                          sortAscending: state.sortAscending,
                          onSearchChanged: (query) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentSearchChanged(query));
                          },
                          onFiltersChanged: ({
                            methodFilter,
                            statusFilter,
                            jenisBankFilter,
                            startDate,
                            endDate,
                            minAmount,
                            maxAmount,
                            clearDates = false,
                            clearAmounts = false,
                          }) {
                            context.read<AdminPaymentBloc>().add(
                                  AdminPaymentFiltersUpdated(
                                    methodFilter: methodFilter,
                                    statusFilter: statusFilter,
                                    jenisBankFilter: jenisBankFilter,
                                    startDate: startDate,
                                    endDate: endDate,
                                    minAmount: minAmount,
                                    maxAmount: maxAmount,
                                    clearDates: clearDates,
                                    clearAmounts: clearAmounts,
                                  ),
                                );
                          },
                          onSortChanged: (col) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentSortChanged(col));
                          },
                          onResetFilters: () {
                            context
                                .read<AdminPaymentBloc>()
                                .add(const AdminPaymentFiltersReset());
                          },
                          onExportPressed: () =>
                              _openExportDialog(context, state.paymentsResult),
                          onPageChanged: (page) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentPageChanged(page));
                          },
                          onViewDetail: (paymentId) {
                            context
                                .read<AdminPaymentBloc>()
                                .add(AdminPaymentDetailRequested(paymentId));
                          },
                          onReconcilePayment: (item) {
                            _confirmReconcilePayment(context, item);
                          },
                          onConfirmCodPayment: (item) {
                            _confirmCodSettlement(context, item);
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
                  'Pusat Manajemen Pembayaran SatSet (Payment Management)',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau seluruh transaksi pembayaran pengiriman pada t_shipment_payments, periksa referensi payment gateway & rekening bank (m_jenis_bank & m_bank), kelola verifikasi setoran COD, serta jalankan rekonsiliasi status secara aman dan idempoten.',
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
              Icons.account_balance_wallet_rounded,
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

