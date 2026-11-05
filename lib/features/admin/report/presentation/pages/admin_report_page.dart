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
import 'package:satset/features/admin/settings/presentation/pages/admin_settings_page.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../data/datasources/admin_report_remote_datasource.dart';
import '../../data/repositories/admin_report_repository_impl.dart';
import '../bloc/admin_report_bloc.dart';
import '../bloc/admin_report_event.dart';
import '../bloc/admin_report_state.dart';
import '../widgets/report_charts_section.dart';
import '../widgets/report_data_table.dart';
import '../widgets/report_detail_dialog.dart';
import '../widgets/report_export_dialog.dart';
import '../widgets/report_filter_panel.dart';
import '../widgets/report_skeleton.dart';
import '../widgets/report_summary_cards.dart';
import '../widgets/report_type_tabs.dart';

class AdminReportPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onLogout;

  const AdminReportPage({
    super.key,
    this.user,
    this.token,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = AdminReportRemoteDataSourceImpl(
      client: SupabaseConfig.client,
    );
    final repository = AdminReportRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => AdminReportBloc(
        repository: repository,
        remoteDataSource: remoteDataSource,
      )..add(const AdminReportStarted()),
      child: AdminReportView(
        currentUser: user,
        token: token,
        onLogout: onLogout,
      ),
    );
  }
}

class AdminReportView extends StatefulWidget {
  final User? currentUser;
  final String? token;
  final VoidCallback? onLogout;

  const AdminReportView({
    super.key,
    this.currentUser,
    this.token,
    this.onLogout,
  });

  @override
  State<AdminReportView> createState() => _AdminReportViewState();
}

class _AdminReportViewState extends State<AdminReportView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cookieWatcherTimer;
  bool? _isAutoLoggingOut;
  bool? _isSidebarOpen;
  bool _isDetailDialogOpen = false;
  bool _isExportDialogOpen = false;

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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Keluar',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin mengakhiri sesi Administrator saat ini?',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
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
              child: const Text('Keluar'),
            ),
          ],
        );
      },
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
    if (route == '/admin/reports') return;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return BlocConsumer<AdminReportBloc, AdminReportState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AdminReportBloc>().add(const AdminReportClearFeedback());
        }
        if (state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AdminReportBloc>().add(const AdminReportClearFeedback());
        }

        if (state.selectedDetail != null && !_isDetailDialogOpen) {
          _isDetailDialogOpen = true;
          showDialog(
            context: context,
            builder: (dialogCtx) => ReportDetailDialog(
              detail: state.selectedDetail!,
              onClose: () => Navigator.of(dialogCtx).pop(),
            ),
          ).then((_) {
            _isDetailDialogOpen = false;
            if (context.mounted) {
              context.read<AdminReportBloc>().add(
                const AdminReportDetailDismissed(),
              );
            }
          });
        }

        if (state.activeExportOutput != null && !_isExportDialogOpen) {
          _isExportDialogOpen = true;
          showDialog(
            context: context,
            builder: (dialogCtx) =>
                BlocBuilder<AdminReportBloc, AdminReportState>(
                  bloc: context.read<AdminReportBloc>(),
                  builder: (_, latestState) {
                    final output =
                        latestState.activeExportOutput ??
                        state.activeExportOutput!;
                    return ReportExportDialog(
                      exportOutput: output,
                      onFormatChanged: (fmt) {
                        context.read<AdminReportBloc>().add(
                          AdminReportExportRequested(fmt),
                        );
                      },
                      onClose: () => Navigator.of(dialogCtx).pop(),
                    );
                  },
                ),
          ).then((_) {
            _isExportDialogOpen = false;
            if (context.mounted) {
              context.read<AdminReportBloc>().add(
                const AdminReportExportDismissed(),
              );
            }
          });
        }
      },
      builder: (context, state) {
        if (state.status == AdminReportStatus.unauthorized) {
          return _buildUnauthorizedScreen(context, isDark, state.errorMessage);
        }

        final sidebar = AdminSidebar(
          activeRoute: '/admin/reports',
          onNavigate: (route) => _handleSidebarNavigation(context, route),
          onLogout: () => _handleLogout(context),
        );

        final topHeader = AdminTopHeader(
          currentUser: widget.currentUser,
          isRefreshing:
              state.isRefreshing || state.status == AdminReportStatus.loading,
          onRefresh: () {
            context.read<AdminReportBloc>().add(const AdminReportRefreshed());
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
        if (state.status == AdminReportStatus.loading ||
            state.status == AdminReportStatus.initial) {
          bodyContent = const AdminReportSkeleton();
        } else if (state.status == AdminReportStatus.error) {
          bodyContent = _buildErrorScreen(context, isDark, state.errorMessage);
        } else {
          bodyContent = Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Judul Halaman
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
                              'Pusat Laporan & Analitik Operasional SatSet Delivery',
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Laporan pengiriman, performa kurir, aktivitas pelanggan, dan transaksi pembayaran secara real-time dari Supabase.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Tab Kategori Laporan & Tombol Ekspor (CSV, Excel, PDF)
                    ReportTypeTabs(
                      selectedReportType: state.filter.reportType,
                      totalFilteredRecords: state.reportData.totalFilteredCount,
                      onReportTypeSelected: (type) {
                        context.read<AdminReportBloc>().add(
                          AdminReportTypeChanged(type),
                        );
                      },
                      onExportRequested: (format) {
                        context.read<AdminReportBloc>().add(
                          AdminReportExportRequested(format),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Panel Filter Lintas Dimensi & Validasi Rentang Tanggal
                    ReportFilterPanel(
                      filter: state.filter,
                      references: state.references,
                      dateValidationError: state.dateValidationError,
                      onDateRangeChanged: (start, end) {
                        context.read<AdminReportBloc>().add(
                          AdminReportDateRangeChanged(
                            startDate: start,
                            endDate: end,
                          ),
                        );
                      },
                      onFilterUpdated: ({
                        shipmentStatusCode,
                        serviceTypeCode,
                        paymentMethod,
                        paymentStatus,
                        courierId,
                        clearCourierId = false,
                      }) {
                        context.read<AdminReportBloc>().add(
                          AdminReportFilterUpdated(
                            shipmentStatusCode: shipmentStatusCode,
                            serviceTypeCode: serviceTypeCode,
                            paymentMethod: paymentMethod,
                            paymentStatus: paymentStatus,
                            courierId: courierId,
                            clearCourierId: clearCourierId,
                          ),
                        );
                      },
                      onResetFilters: () {
                        context.read<AdminReportBloc>().add(
                          const AdminReportFiltersReset(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Ringkasan Metrik Utama Sesuai Jenis Laporan
                    ReportSummaryCards(reportData: state.reportData),
                    const SizedBox(height: 16),

                    // 4. Visualisasi Grafik Laporan
                    ReportChartsSection(reportData: state.reportData),
                    const SizedBox(height: 16),

                    // 5. Tabel Data Laporan (Search, Sort, Pagination, Total, Detail)
                    ReportDataTable(
                      reportData: state.reportData,
                      onSearchChanged: (query) {
                        context.read<AdminReportBloc>().add(
                          AdminReportSearchChanged(query),
                        );
                      },
                      onSortChanged: (column, ascending) {
                        context.read<AdminReportBloc>().add(
                          AdminReportSortChanged(
                            sortColumn: column,
                            sortAscending: ascending,
                          ),
                        );
                      },
                      onPageChanged: (page) {
                        context.read<AdminReportBloc>().add(
                          AdminReportPageChanged(page),
                        );
                      },
                      onViewDetail: (reportType, recordId) {
                        context.read<AdminReportBloc>().add(
                          AdminReportDetailRequested(
                            reportType: reportType,
                            recordId: recordId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (state.isRefreshing || state.isDetailLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        }

        final mainColumn = Column(
          children: [
            topHeader,
            Expanded(child: bodyContent),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            drawer: Drawer(child: sidebar),
            body: mainColumn,
          );
        }
      },
    );
  }

  Widget _buildUnauthorizedScreen(
    BuildContext context,
    bool isDark,
    String? message,
  ) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_outlined, size: 54, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Akses Ditolak (403)',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Halaman ini hanya diizinkan untuk Administrator resmi (m_employee.id_users_role = 1).',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
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

  Widget _buildErrorScreen(
    BuildContext context,
    bool isDark,
    String? message,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.error),
            const SizedBox(height: 14),
            Text(
              'Gagal Memuat Data Laporan',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Terjadi kendala saat mengambil data laporan dari database Supabase.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<AdminReportBloc>().add(const AdminReportStarted());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}

