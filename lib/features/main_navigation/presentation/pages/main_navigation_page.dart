import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/pages/login_page.dart';
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

  const MainNavigationPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.token,
    this.user,
    this.initialTab = NavigationTab.home,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final NavigationBloc _navigationBloc;

  @override
  void initState() {
    super.initState();
    _navigationBloc = NavigationBloc();
    if (widget.initialTab != NavigationTab.home) {
      _navigationBloc.add(NavigationTabChanged(widget.initialTab));
    }
  }

  @override
  void dispose() {
    _navigationBloc.close();
    super.dispose();
  }

  void _openCreateShipmentSheet() {
    CreateShipmentSheet.show(
      context,
      onOrderCreated: (orderData) {
        _navigationBloc.add(const NavigationTabChanged(NavigationTab.orders));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dibuat! Kurir sedang ditugaskan.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _onLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navigationBloc,
      child: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
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
          // Petakan tab enum ke index IndexedStack
          int stackIndex;
          switch (state.currentTab) {
            case NavigationTab.home:
              stackIndex = 0;
              break;
            case NavigationTab.liveTrack:
              stackIndex = 1;
              break;
            case NavigationTab.send:
              // Menu kirim dihandle oleh modal sheet, biarkan di halaman saat ini
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
            // IndexedStack memastikan aliran data langsung (live stream)
            // dan posisi peta tidak terputus atau memuat ulang saat berpindah tab
            body: IndexedStack(
              index: stackIndex,
              children: [
                // 1. Beranda (Dashboard Pengiriman Real-Time)
                DashboardPage(
                  isDarkMode: widget.isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  token: widget.token,
                  user: widget.user,
                  showBottomNav: false,
                ),

                // 2. Lacak Live (Peta Interaktif Layar Penuh dari fitur livetrack)
                const LiveTrackPage(),

                // 3. Pesanan (Daftar Kiriman Saya / Paket Masuk dari fitur order)
                const OrdersPage(),

                // 4. Akun (Alamat, Metode Pembayaran, Klaim Asuransi, Pengaturan)
                AccountPage(
                  isDarkMode: widget.isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  onLogout: _onLogout,
                ),
              ],
            ),

            // Bilah Navigasi Bawah Utama (5 Menu: Beranda, Lacak Live, + Kirim, Pesanan, Akun)
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
        },
      ),
    );
  }
}
