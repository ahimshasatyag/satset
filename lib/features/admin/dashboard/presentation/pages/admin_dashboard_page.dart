import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/auth/data/utils/admin_cookie_manager.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/features/admin/delivery/presentation/pages/admin_delivery_page.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';

import '../../data/datasources/admin_dashboard_remote_datasource.dart';
import '../../data/repositories/admin_dashboard_repository_impl.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';

import 'package:satset/features/admin/navbar/presentation/widgets/admin_sidebar.dart';
import 'package:satset/features/admin/navbar/presentation/widgets/admin_top_header.dart';

import '../widgets/courier_summary_card.dart';
import '../widgets/payment_summary_card.dart';
import '../widgets/recent_activities_view.dart';
import '../widgets/recent_shipments_table.dart';
import '../widgets/shipment_detail_dialog.dart';
import '../widgets/shipment_status_chart.dart';
import '../widgets/shipment_trend_chart.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/dashboard_skeleton.dart';

class AdminDashboardPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminDashboardPage({super.key, this.user, this.token, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminDashboardRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminDashboardRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (context) => AdminDashboardBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminDashboardStarted()),
      child: AdminDashboardView(currentUser: user, onLogout: onLogout),
    );
  }
}

class AdminDashboardView extends StatefulWidget {
  final User? currentUser;
  final VoidCallback? onLogout;

  const AdminDashboardView({super.key, this.currentUser, this.onLogout});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cookieWatcherTimer;
  bool? _isAutoLoggingOut;
  bool? _isSidebarOpen;

  bool get _sidebarOpen => _isSidebarOpen ?? true;
  bool get _autoLoggingOut => _isAutoLoggingOut ?? false;

  @override
  void initState() {
    super.initState();
    // 1. Cek ketersediaan cookie auth token saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AdminCookieManager.hasAuthTokenCookie()) {
        _handleAutoLogoutOnMissingCookie();
      }
    });

    // 2. Pantau keberadaan cookie auth token secara berkala;
    // jika cookie dihapus atau habis masa berlakunya, otomatis logout sendiri
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
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // 1. Tampilkan dialog konfirmasi logout
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            const Text('Keluar dari Akun Admin?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri sesi Administrator saat ini? Anda harus login kembali untuk mengakses panel kendali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _isAutoLoggingOut = true;
    _cookieWatcherTimer?.cancel();

    // 2. Hapus sesi lokal administrator di SharedPreferences & Cookies
    final localDataSource = AdminAuthLocalDataSourceImpl();
    await localDataSource.deleteAdmin();

    // 3. Sign out Supabase auth
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    // 4. Trigger callback logout pada level root (main.dart)
    widget.onLogout?.call();

    // 5. Bersihkan stack navigasi dan arahkan ke halaman login admin
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (route) => false,
      );
    }
  }

  void _showDetailModal(BuildContext context, state) {
    if (state.selectedShipmentDetail != null) {
      showDialog(
        context: context,
        builder: (_) => ShipmentDetailDialog(
          detail: state.selectedShipmentDetail!,
          onClose: () {
            Navigator.of(context).pop();
            context.read<AdminDashboardBloc>().add(
              const AdminDashboardShipmentDetailDismissed(),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminDashboardBloc, AdminDashboardState>(
      listener: (context, state) {
        if (state.selectedShipmentDetail != null && !state.isDetailLoading) {
          _showDetailModal(context, state);
        }
        if (state.detailErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.detailErrorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // 1. Tampilan Akses Ditolak (Unauthorized) jika bukan Admin resmi
        if (state.status == AdminDashboardStatus.unauthorized) {
          return _buildUnauthorizedScreen(context, isDark, state.errorMessage);
        }

        // 2. Tampilan Loading awal dengan Skeleton
        if (state.status == AdminDashboardStatus.loading) {
          final loadingSidebar = AdminSidebar(
            activeRoute: '/admin/dashboard',
            onNavigate: (_) {},
            onLogout: () => _handleLogout(context),
          );
          final loadingContent = Column(
            children: [
              AdminTopHeader(
                currentUser: widget.currentUser,
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
              const Expanded(child: AdminDashboardSkeleton()),
            ],
          );

          if (isDesktop) {
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
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
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              drawer: Drawer(child: loadingSidebar),
              body: loadingContent,
            );
          }
        }

        // 3. Tampilan Gagal / Error
        if (state.status == AdminDashboardStatus.error) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
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
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Dashboard',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ??
                          'Terjadi kesalahan saat menghubungkan ke basis data.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<AdminDashboardBloc>().add(
                          const AdminDashboardStarted(),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 4. Layout Utama: Sidebar + Konten Dashboard
        final sidebar = AdminSidebar(
          activeRoute: '/admin/dashboard',
          onNavigate: (route) {
            if (route == '/admin/shipments') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AdminDeliveryPage(
                    user: widget.currentUser,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
            }
          },
          onLogout: () => _handleLogout(context),
        );

        final mainContent = Column(
          children: [
            // Header Top Bar
            AdminTopHeader(
              currentUser: widget.currentUser,
              isRefreshing: state.isRefreshing,
              onRefresh: () {
                context.read<AdminDashboardBloc>().add(
                  const AdminDashboardRefreshed(),
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
            ),

            // Scrollable Body Konten Dashboard
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
                    context.read<AdminDashboardBloc>().add(
                      const AdminDashboardRefreshed(),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner Ringkasan Dashboard
                        _buildWelcomeBanner(context, isDark),
                        const SizedBox(height: 24),

                        // 1. Statistics Cards (Total pengiriman, pending, proses, berhasil, gagal, customer, employee, kurir aktif)
                        StatisticsCards(stats: state.stats),
                        const SizedBox(height: 24),

                        // 2. Charts Section (Trend Chart + Status Distribution Chart)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 960) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ShipmentTrendChart(
                                      dailyTrends: state.stats.dailyTrends,
                                      weeklyTrends: state.stats.weeklyTrends,
                                      monthlyTrends: state.stats.monthlyTrends,
                                      activePeriod: state.activeTrendPeriod,
                                      onPeriodChanged: (period) {
                                        context.read<AdminDashboardBloc>().add(
                                          AdminDashboardTrendPeriodChanged(
                                            period,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: ShipmentStatusChart(
                                      distributions:
                                          state.stats.statusDistributions,
                                      totalShipments:
                                          state.stats.totalShipments,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  ShipmentTrendChart(
                                    dailyTrends: state.stats.dailyTrends,
                                    weeklyTrends: state.stats.weeklyTrends,
                                    monthlyTrends: state.stats.monthlyTrends,
                                    activePeriod: state.activeTrendPeriod,
                                    onPeriodChanged: (period) {
                                      context.read<AdminDashboardBloc>().add(
                                        AdminDashboardTrendPeriodChanged(
                                          period,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ShipmentStatusChart(
                                    distributions:
                                        state.stats.statusDistributions,
                                    totalShipments: state.stats.totalShipments,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // 3. Summaries Section (Payment Summary + Courier Summary)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 960) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PaymentSummaryCard(
                                      paymentSummary:
                                          state.stats.paymentSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: CourierSummaryCard(
                                      couriers: state.couriers,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  PaymentSummaryCard(
                                    paymentSummary: state.stats.paymentSummary,
                                  ),
                                  const SizedBox(height: 20),
                                  CourierSummaryCard(couriers: state.couriers),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // 4. Recent Shipments Table (Filter status, layanan, tanggal, pagination, pencarian, detail popup)
                        RecentShipmentsTable(
                          shipmentsResult: state.shipmentsResult,
                          isLoading: state.isTableLoading,
                          searchQuery: state.searchQuery,
                          selectedStatus: state.statusFilter,
                          selectedService: state.serviceFilter,
                          startDate: state.startDate,
                          endDate: state.endDate,
                          statusOptions: state.statusOptions,
                          serviceOptions: state.serviceOptions,
                          onSearchChanged: (query) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardSearchQueryChanged(query),
                            );
                          },
                          onStatusChanged: (status) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardStatusFilterChanged(status),
                            );
                          },
                          onServiceChanged: (service) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardServiceFilterChanged(service),
                            );
                          },
                          onDateRangeChanged: (start, end) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardDateRangeFilterChanged(
                                startDate: start,
                                endDate: end,
                              ),
                            );
                          },
                          onPageChanged: (page) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardPageChanged(page),
                            );
                          },
                          onSelectShipment: (id) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardShipmentDetailRequested(id),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // 5. Recent Activities Timeline (dari t_shipment_tracking)
                        RecentActivitiesView(
                          activities: state.activities,
                          onSelectShipment: (id) {
                            context.read<AdminDashboardBloc>().add(
                              AdminDashboardShipmentDetailRequested(id),
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
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
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
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            drawer: Drawer(child: sidebar),
            body: mainContent,
          );
        }
      },
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Admin SatSet Delivery',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau seluruh aktivitas operasional logistik, penugasan kurir, perputaran pembayaran, dan status paket pengiriman secara real-time.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedScreen(
    BuildContext context,
    bool isDark,
    String? message,
  ) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  size: 54,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Akses Khusus Administrator',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Halaman ini diproteksi ketat dan hanya dapat diakses oleh akun Administrator (id_users_role = 1). Akun Pelanggan maupun Kurir tidak memiliki izin mengakses modul ini.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard'),
                    child: const Text('Ke Pelanggan'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _handleLogout(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Keluar & Ganti Akun'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
