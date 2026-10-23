import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../courier/tasks/presentation/pages/courier_tasks_page.dart';
import '../../../courier/barcode_scanner/presentation/pages/courier_barcode_scanner_page.dart';

import 'package:satset/features/customer/dashboard/presentation/pages/dashboard_page.dart';
import 'package:satset/features/customer/livetrack/presentation/pages/live_track_page.dart';
import 'package:satset/features/customer/order/presentation/pages/orders_page.dart';
import 'package:satset/features/customer/shipments/presentation/widgets/create_shipment_sheet.dart';

import '../../domain/entities/navigation_item.dart';
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_event.dart';
import '../bloc/navigation_state.dart';
import '../widgets/satset_bottom_navigation_bar.dart';

class MainNavigationPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final String? token;
  final User? user;
  final NavigationTab initialTab;
  final CourierNavigationTab initialCourierTab;

  /// Flag eksplisit untuk mengaktifkan mode navigasi Kurir
  final bool isCourierMode;

  const MainNavigationPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.token,
    this.user,
    this.initialTab = NavigationTab.home,
    this.initialCourierTab = CourierNavigationTab.tasks,
    this.isCourierMode = false,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final NavigationBloc _navigationBloc;

  bool get _isCourier {
    return widget.isCourierMode ||
        (widget.user != null && widget.user!.isCourier);
  }

  @override
  void initState() {
    super.initState();
    _navigationBloc = NavigationBloc();

    if (_isCourier) {
      if (widget.initialCourierTab != CourierNavigationTab.tasks) {
        _navigationBloc.add(
          CourierNavigationTabChanged(widget.initialCourierTab),
        );
      }
      final uId = widget.user?.id ?? '';
      final uEmail = widget.user?.email;
      if (uId.isNotEmpty) {
        _navigationBloc.add(
          NavigationCourierAuthChecked(userId: uId, email: uEmail),
        );
      }
    } else {
      if (widget.initialTab != NavigationTab.home) {
        _navigationBloc.add(NavigationTabChanged(widget.initialTab));
      }
    }
  }

  @override
  void dispose() {
    _navigationBloc.close();
    super.dispose();
  }

  void _handleLogout() {
    _navigationBloc.add(const NavigationLogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openCreateShipmentSheet() {
    CreateShipmentSheet.show(
      context,
      onOrderCreated: (orderData) {
        _navigationBloc.add(const NavigationTabChanged(NavigationTab.orders));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pesanan berhasil dibuat! Kurir sedang ditugaskan.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navigationBloc,
      child: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state.isSessionExpired) {
            _handleLogout();
            return;
          }

          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isCourier) {
            return _buildCourierScaffold(context, state);
          }

          return _buildCustomerScaffold(context, state);
        },
      ),
    );
  }

  // =========================================================================
  // NAVIGASI KHUSUS KURIR (COURIER MAIN NAVIGATION)
  // =========================================================================

  Widget _buildCourierScaffold(BuildContext context, NavigationState state) {
    // 1. Tangani otorisasi: hanya akun dengan id_users_role == 2
    if (state.isCourierAuthorized == false && widget.user?.isCourier != true) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: CustomEmptyState(
                icon: Icons.gpp_bad_rounded,
                title: 'Akses Dibatasi',
                description: state.errorMessage ??
                    'Halaman ini hanya dapat diakses oleh akun resmi kurir SatSet dengan id_users_role=2 pada tabel m_employee.',
                buttonText: 'Kembali ke Login',
                onButtonPressed: _handleLogout,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Pemetaan tab kurir ke Index (Tasks, Pelacakan, Scan, Riwayat, Akun)
    int stackIndex;
    switch (state.currentCourierTab) {
      case CourierNavigationTab.tasks:
        stackIndex = 0;
        break;
      case CourierNavigationTab.trackingCourier:
        stackIndex = 1;
        break;
      case CourierNavigationTab.scan:
        stackIndex = 2;
        break;
      case CourierNavigationTab.history:
        stackIndex = 3;
        break;
      case CourierNavigationTab.account:
        stackIndex = 4;
        break;
    }

    return Scaffold(
      body: IndexedStack(
        index: stackIndex,
        children: [
          // 0. tasks/ -> Halaman Utama Kurir setelah login (CourierTasksPage)
          CourierTasksPage(
            user: widget.user,
            onNavigateToScanner: () {
              _navigationBloc.add(
                const CourierNavigationTabChanged(CourierNavigationTab.scan),
              );
            },
            onNavigateToLocationTracking: () {
              _navigationBloc.add(
                const CourierNavigationTabChanged(
                  CourierNavigationTab.trackingCourier,
                ),
              );
            },
            onNavigateToTaskHistory: () {
              _navigationBloc.add(
                const CourierNavigationTabChanged(CourierNavigationTab.history),
              );
            },
          ),

          // 1. tracking_courier/ -> Placeholder delegasi fitur location_tracking
          const SizedBox.shrink(),

          // 2. scan/ -> Halaman Barcode Scanner khusus Courier
          CourierBarcodeScannerPage(
            user: widget.user,
            onNavigateToTasks: () {
              _navigationBloc.add(
                const CourierNavigationTabChanged(CourierNavigationTab.tasks),
              );
            },
          ),

          // 3. history/ -> Placeholder delegasi fitur task_history
          const SizedBox.shrink(),

          // 4. account/ -> Halaman Akun yang sudah ada di aplikasi
          AccountPage(
            user: widget.user,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            onLogout: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: SatSetBottomNavigationBar.courier(
        currentTab: state.currentCourierTab,
        onTabSelected: (tab) {
          _navigationBloc.add(CourierNavigationTabChanged(tab));
        },
        onScanActionTap: () {
          _navigationBloc.add(
            const CourierNavigationTabChanged(CourierNavigationTab.scan),
          );
        },
        activeTasksCount: state.activeTasksCount,
        hasActiveTask: state.hasActiveTask,
      ),
    );
  }

  // =========================================================================
  // NAVIGASI PELANGGAN (CUSTOMER MAIN NAVIGATION - BACKWARD COMPATIBLE)
  // =========================================================================

  Widget _buildCustomerScaffold(BuildContext context, NavigationState state) {
    int stackIndex;
    switch (state.currentTab) {
      case NavigationTab.home:
        stackIndex = 0;
        break;
      case NavigationTab.liveTrack:
        stackIndex = 1;
        break;
      case NavigationTab.send:
        stackIndex = 0;
        break;
      case NavigationTab.orders:
        stackIndex = 2;
        break;
      case NavigationTab.account:
        stackIndex = 3;
        break;
    }

    return Scaffold(
      body: IndexedStack(
        index: stackIndex,
        children: [
          DashboardPage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            token: widget.token,
            user: widget.user,
            showBottomNav: false,
          ),
          const LiveTrackPage(),
          const OrdersPage(),
          AccountPage(
            user: widget.user,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            onLogout: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: SatSetBottomNavigationBar(
        currentTab: state.currentTab,
        onTabSelected: (tab) {
          if (tab == NavigationTab.send) {
            _openCreateShipmentSheet();
          } else {
            _navigationBloc.add(NavigationTabChanged(tab));
          }
        },
        onSendActionTap: _openCreateShipmentSheet,
      ),
    );
  }
}

/// Helper wrapper khusus rute Kurir (CourierMainNavigationPage)
class CourierMainNavigationPage extends StatelessWidget {
  final User? user;
  final String? token;
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final CourierNavigationTab initialTab;

  const CourierMainNavigationPage({
    super.key,
    this.user,
    this.token,
    this.onToggleTheme,
    this.isDarkMode,
    this.initialTab = CourierNavigationTab.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return MainNavigationPage(
      user: user,
      token: token,
      onToggleTheme: onToggleTheme,
      isDarkMode: isDarkMode,
      isCourierMode: true,
      initialCourierTab: initialTab,
    );
  }
}
