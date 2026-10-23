import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/auth/presentation/pages/login_page.dart';
import 'package:satset/features/main_navigation/domain/entities/navigation_item.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_bloc.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_event.dart';
import 'package:satset/features/main_navigation/presentation/pages/main_navigation_page.dart';
import 'package:satset/features/main_navigation/presentation/widgets/satset_bottom_navigation_bar.dart';
import 'package:satset/features/customer/shipments/presentation/widgets/create_shipment_sheet.dart';
import 'package:satset/features/notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_active_shipment_usecase.dart';
import '../../domain/usecases/get_live_shipment_stream_usecase.dart';
import '../../domain/usecases/get_recent_shipments_usecase.dart';
import '../../domain/usecases/get_shipment_status_summary_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/track_shipment_usecase.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_promo_carousel.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/live_shipment_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_shipments_list.dart';
import '../widgets/shipment_detail_sheet.dart';
import '../widgets/shipment_summary_cards.dart';
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
  late final GetShipmentStatusSummaryUseCase _getShipmentStatusSummaryUseCase;
  late final TrackShipmentUseCase _trackShipmentUseCase;
  late final GetUserProfileUseCase _getUserProfileUseCase;
  late final DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Clean Architecture Dependencies dengan Supabase
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
    _getShipmentStatusSummaryUseCase = GetShipmentStatusSummaryUseCase(_repository);
    _trackShipmentUseCase = TrackShipmentUseCase(_repository);
    _getUserProfileUseCase = GetUserProfileUseCase(_repository);

    _dashboardBloc = DashboardBloc(
      getLiveShipmentStreamUseCase: _getLiveStreamUseCase,
      getActiveShipmentUseCase: _getActiveShipmentUseCase,
      getRecentShipmentsUseCase: _getRecentShipmentsUseCase,
      getShipmentStatusSummaryUseCase: _getShipmentStatusSummaryUseCase,
      trackShipmentUseCase: _trackShipmentUseCase,
      getUserProfileUseCase: _getUserProfileUseCase,
      repository: _repository,
    )..add(DashboardInitializeRequested(
        userId: widget.user?.id,
        customerId: widget.user?.id != null ? int.tryParse(widget.user!.id) : null,
      ));
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
        _dashboardBloc.add(const DashboardRefreshRequested());
        _navigateToTab(NavigationTab.orders);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan pengiriman berhasil dibuat!'),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
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
                final result = state.searchResult!;
                _dashboardBloc.add(const DashboardClearSearchResult());
                ShipmentDetailSheet.show(context, result);
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
                return const DashboardSkeleton();
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
                            _dashboardBloc.add(DashboardInitializeRequested(
                              userId: widget.user?.id,
                              customerId: widget.user?.id != null
                                  ? int.tryParse(widget.user!.id)
                                  : null,
                            ));
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
            // 1. Header (Sapaan pelanggan dari m_users, alamat/lokasi, lonceng notifikasi)
            DashboardHeader(
              profile: state.userProfile,
              onNotificationTap: _onNotificationTap,
              onProfileTap: () {
                _showProfileSheet(context, state.userProfile);
              },
            ),

            // 2. Kolom Pencarian Nomor Resi (Smart Tracking Bar & Barcode Scanner)
            SmartTrackingBar(
              onTrack: _onTrackSubmitted,
              isLoading: state.isSearching,
              searchHistory: state.searchHistory,
              onClearHistory: () {
                _dashboardBloc.add(const DashboardClearHistoryRequested());
              },
            ),

            // 3. Carousel Slider Otomatis Promo SatSet
            DashboardPromoCarousel(
              onBannerTap: (index) {
                _openCreateShipmentSheet();
              },
            ),
            const SizedBox(height: 2),

            // 4. Kartu Ringkasan Status Pengiriman (Menunggu Konfirmasi, Sedang Diproses, Dalam Perjalanan, Telah Terkirim)
            ShipmentSummaryCards(
              summary: state.statusSummary,
              activeFilter: state.activeStatusFilter,
              onFilterSelected: (filter) {
                _dashboardBloc.add(DashboardStatusFilterChanged(filter));
              },
            ),
            const SizedBox(height: 8),

            // 4. Tombol Aksi Cepat (Buat Pengiriman, Pengiriman Saya, Pelacakan, Cek Tarif)
            QuickActionsGrid(
              onActionTap: (actionTitle) {
                switch (actionTitle) {
                  case 'Buat Pengiriman':
                    _openCreateShipmentSheet();
                    break;
                  case 'Pengiriman Saya':
                    _navigateToTab(NavigationTab.orders);
                    break;
                  case 'Pelacakan':
                    _navigateToTab(NavigationTab.liveTrack);
                    break;
                  case 'Cek Tarif':
                    _showTarifCalculatorSheet(context);
                    break;
                  default:
                    break;
                }
              },
            ),
            const SizedBox(height: 8),

            // 5. Kartu Pengiriman Aktif (Live Shipment Card)
            // Mengalir dari Supabase Realtime Stream
            StreamBuilder<Shipment?>(
              stream: _getLiveStreamUseCase(
                customerId: int.tryParse(state.userProfile.id),
              ),
              initialData: state.activeShipment,
              builder: (context, snapshot) {
                final liveShipment = snapshot.data ?? state.activeShipment;
                return LiveShipmentCard(
                  shipment: liveShipment,
                  onLiveTrackTap: () => _navigateToTab(NavigationTab.liveTrack),
                  onCreateShipmentTap: _openCreateShipmentSheet,
                  onShipmentDetailTap: (shipment) {
                    ShipmentDetailSheet.show(context, shipment);
                  },
                );
              },
            ),
            const SizedBox(height: 8),

            // 6. Bagian Pengiriman Terbaru (Recent Shipments List)
            RecentShipmentsList(
              shipments: state.recentShipments,
              activeFilter: state.activeStatusFilter,
              onSeeAllTap: () => _navigateToTab(NavigationTab.orders),
              onShipmentTap: (shipment) {
                ShipmentDetailSheet.show(context, shipment);
              },
            ),
            const SizedBox(height: 28),
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
                  CustomButton(
                    text: 'Lanjutkan Buat Pesanan (+ Kirim)',
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openCreateShipmentSheet();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user?.email ?? profile.email,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    profile.locationDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
