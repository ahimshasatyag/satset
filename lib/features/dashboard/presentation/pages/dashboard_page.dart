import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../main_navigation/domain/entities/navigation_item.dart';
import '../../../main_navigation/presentation/bloc/navigation_bloc.dart';
import '../../../main_navigation/presentation/bloc/navigation_event.dart';
import '../../../main_navigation/presentation/pages/main_navigation_page.dart';
import '../../../main_navigation/presentation/widgets/satset_bottom_navigation_bar.dart';
import '../../../order/presentation/widgets/create_shipment_sheet.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_active_shipment_usecase.dart';
import '../../domain/usecases/get_live_shipment_stream_usecase.dart';
import '../../domain/usecases/get_recent_shipments_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/track_shipment_usecase.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/live_shipment_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_shipments_list.dart';
import '../widgets/smart_tracking_bar.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final String? token;
  final User? user;
  final bool showBottomNav;
  final ValueChanged<NavigationTab>? onNavigateTab;

  const DashboardPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.token,
    this.user,
    this.showBottomNav = true,
    this.onNavigateTab,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardRemoteDataSource _remoteDataSource;
  late final DashboardLocalDataSource _localDataSource;
  late final DashboardRepositoryImpl _repository;
  late final GetLiveShipmentStreamUseCase _getLiveStreamUseCase;
  late final GetActiveShipmentUseCase _getActiveShipmentUseCase;
  late final GetRecentShipmentsUseCase _getRecentShipmentsUseCase;
  late final TrackShipmentUseCase _trackShipmentUseCase;
  late final GetUserProfileUseCase _getUserProfileUseCase;
  late final DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Clean Architecture Dependencies dengan Token & User terautentikasi
    _remoteDataSource = DashboardRemoteDataSourceImpl(
      authToken: widget.token,
      currentUser: widget.user,
    );
    _localDataSource = DashboardLocalDataSourceImpl();
    _repository = DashboardRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
    _getLiveStreamUseCase = GetLiveShipmentStreamUseCase(_repository);
    _getActiveShipmentUseCase = GetActiveShipmentUseCase(_repository);
    _getRecentShipmentsUseCase = GetRecentShipmentsUseCase(_repository);
    _trackShipmentUseCase = TrackShipmentUseCase(_repository);
    _getUserProfileUseCase = GetUserProfileUseCase(_repository);

    _dashboardBloc = DashboardBloc(
      getLiveShipmentStreamUseCase: _getLiveStreamUseCase,
      getActiveShipmentUseCase: _getActiveShipmentUseCase,
      getRecentShipmentsUseCase: _getRecentShipmentsUseCase,
      trackShipmentUseCase: _trackShipmentUseCase,
      getUserProfileUseCase: _getUserProfileUseCase,
      repository: _repository,
    )..add(const DashboardInitializeRequested());
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  void _navigateToTab(NavigationTab tab) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tab);
      return;
    }

    try {
      final navBloc = context.read<NavigationBloc>();
      navBloc.add(NavigationTabChanged(tab));
    } catch (_) {
      if (tab == NavigationTab.send) {
        _openCreateShipmentSheet();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MainNavigationPage(
              initialTab: tab,
              isDarkMode: widget.isDarkMode,
              onToggleTheme: widget.onToggleTheme,
              token: widget.token,
              user: widget.user,
            ),
          ),
        );
      }
    }
  }

  void _openCreateShipmentSheet() {
    CreateShipmentSheet.show(
      context,
      onOrderCreated: (orderData) {
        _navigateToTab(NavigationTab.orders);
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

  void _onNotificationTap() {
    _dashboardBloc.add(const DashboardNotificationTapped());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pembaruan status kurir telah ditandai dibaca.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onTrackSubmitted(String query) {
    _dashboardBloc.add(DashboardTrackNumberSubmitted(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _dashboardBloc,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: BlocConsumer<DashboardBloc, DashboardState>(
            listener: (context, state) {
              if (state is DashboardLoaded && state.searchResult != null) {
                _showSearchResultDialog(context, state.searchResult!);
              } else if (state is DashboardLoaded && state.searchError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.searchError!),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(
                  child: CustomLoading(
                    message: 'Menghubungkan ke Real-Time Stream SatSet...',
                  ),
                );
              }

              if (state is DashboardError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 56,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Coba Lagi',
                          onPressed: () {
                            _dashboardBloc
                                .add(const DashboardInitializeRequested());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DashboardLoaded) {
                return _buildDashboardContent(context, state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? SatSetBottomNavigationBar(
                currentTab: NavigationTab.home,
                onTabSelected: (tab) {
                  if (tab == NavigationTab.send) {
                    _openCreateShipmentSheet();
                  } else if (tab != NavigationTab.home) {
                    _navigateToTab(tab);
                  }
                },
                onSendActionTap: _openCreateShipmentSheet,
              )
            : null,
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _dashboardBloc.add(const DashboardRefreshRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Sapaan personal, GPS live indicator, Lonceng notifikasi)
            DashboardHeader(
              profile: state.userProfile,
              onNotificationTap: _onNotificationTap,
              onProfileTap: () {
                _showProfileSheet(context, state.userProfile);
              },
            ),

            // Indikator Sesi Token Autentikasi Aktif
            if (widget.token != null && widget.token!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sesi Aktif: ${widget.token}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Kolom Pencarian Pintar (Smart Tracking Bar & Scanner)
            SmartTrackingBar(
              onTrack: _onTrackSubmitted,
              isLoading: state.isSearching,
            ),
            const SizedBox(height: 6),

            // 3. Kartu Pengiriman Aktif (Live Shipment Card)
            // Terhubung langsung ke Stream Real-Time via StreamBuilder
            StreamBuilder<Shipment>(
              stream: _getLiveStreamUseCase(),
              initialData: state.activeShipment,
              builder: (context, snapshot) {
                final liveShipment = snapshot.data ?? state.activeShipment;
                return LiveShipmentCard(
                  shipment: liveShipment,
                  onLiveTrackTap: () => _navigateToTab(NavigationTab.liveTrack),
                );
              },
            ),

            // 4. Deretan Menu Aksi Cepat (Quick Actions Grid)
            QuickActionsGrid(
              onActionTap: (actionTitle) {
                switch (actionTitle) {
                  case 'Kirim Paket':
                    _openCreateShipmentSheet();
                    break;
                  case 'Drop-off':
                    _navigateToTab(NavigationTab.liveTrack);
                    break;
                  case 'Klaim Asuransi':
                    _navigateToTab(NavigationTab.account);
                    break;
                  case 'Cek Tarif':
                    _showTarifCalculatorSheet(context);
                    break;
                  default:
                    break;
                }
              },
            ),

            // 5. Riwayat Pengiriman Terakhir (Recent Shipments)
            RecentShipmentsList(
              shipments: state.recentShipments,
              onSeeAllTap: () => _navigateToTab(NavigationTab.orders),
              onShipmentTap: (shipment) => _navigateToTab(NavigationTab.orders),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTarifCalculatorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        int weightKg = 1;
        String origin = 'Jakarta Selatan';
        String destination = 'Bandung';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final instantPrice = weightKg * 24000;
            final samedayPrice = weightKg * 18000;
            final regulerPrice = weightKg * 12000;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kalkulator Cek Ongkir',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rute: $origin ➔ $destination',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Berat Paket:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: weightKg > 1
                                ? () => setSheetState(() => weightKg--)
                                : null,
                          ),
                          Text('$weightKg Kg',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => setSheetState(() => weightKg++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bolt_rounded, color: AppColors.primary),
                    title: const Text('SATSET Instant (1-2 Jam)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    trailing: Text(
                      'Rp ${instantPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded, color: AppColors.secondary),
                    title: const Text('SATSET Sameday (6-8 Jam)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    trailing: Text(
                      'Rp ${samedayPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_shipping_outlined, color: AppColors.tertiary),
                    title: const Text('SATSET Reguler (1-2 Hari)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    trailing: Text(
                      'Rp ${regulerPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openCreateShipmentSheet();
                    },
                    child: const Text('Lanjutkan Buat Pesanan (+ Kirim)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSearchResultDialog(BuildContext context, Shipment shipment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Resi: ${shipment.trackingNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Barang: ${shipment.itemName}'),
            const SizedBox(height: 4),
            Text('Status: ${shipment.status.label}'),
            const SizedBox(height: 4),
            Text('Layanan: ${shipment.serviceType}'),
            const SizedBox(height: 4),
            Text('Posisi: ${shipment.courierPosition.address}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToTab(NavigationTab.liveTrack);
            },
            child: const Text('Lacak di Peta'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.user?.name ?? profile.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user?.email ?? 'Lokasi GPS: ${profile.locationDisplay}',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Detail Token Sesi
              if (widget.token != null && widget.token!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Token: ${widget.token}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.onToggleTheme != null)
                ListTile(
                  leading: Icon(
                    widget.isDarkMode == true
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  title: Text(widget.isDarkMode == true
                      ? 'Beralih ke Mode Terang'
                      : 'Beralih ke Mode Gelap'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onToggleTheme!();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_rounded,
                    color: AppColors.primary),
                title: const Text('Buka Pengaturan Akun Lengkap'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _navigateToTab(NavigationTab.account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined,
                    color: AppColors.primary),
                title: const Text('Halaman Login & Autentikasi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Tutup',
                isFullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
