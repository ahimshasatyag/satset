import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../data/datasources/live_track_local_datasource.dart';
import '../../data/datasources/live_track_remote_datasource.dart';
import '../../data/repositories/live_track_repository_impl.dart';
import '../../domain/entities/live_track_shipment.dart';
import '../../domain/usecases/get_live_tracking_orders_stream_usecase.dart';
import '../bloc/live_track_bloc.dart';
import '../bloc/live_track_event.dart';
import '../bloc/live_track_state.dart';
import '../widgets/live_track_courier_card.dart';
import '../widgets/live_track_filter_bar.dart';
import '../widgets/live_track_map.dart';
import '../widgets/live_track_map_controls.dart';
import '../widgets/live_track_status_pill.dart';
import '../widgets/live_track_top_bar.dart';

class LiveTrackPage extends StatefulWidget {
  final OrderDirection? initialDirection;
  final String? initialTrackingNumber;

  const LiveTrackPage({
    super.key,
    this.initialDirection,
    this.initialTrackingNumber,
  });

  @override
  State<LiveTrackPage> createState() => _LiveTrackPageState();
}

class _LiveTrackPageState extends State<LiveTrackPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  LiveTrackBloc? _internalBloc;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _internalBloc?.close();
    super.dispose();
  }

  LiveTrackBloc _getOrCreateBloc(BuildContext context) {
    try {
      return BlocProvider.of<LiveTrackBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        final remote = LiveTrackRemoteDataSourceImpl();
        final local = LiveTrackLocalDataSourceImpl();
        final repo = LiveTrackRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );
        final useCase = GetLiveTrackingOrdersStreamUseCase(repo);
        _internalBloc = LiveTrackBloc(
          getLiveTrackingOrdersStreamUseCase: useCase,
        );
        if (widget.initialDirection != null) {
          _internalBloc!.add(
            LiveTrackDirectionChanged(widget.initialDirection!),
          );
        }
      }
      return _internalBloc!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<LiveTrackBloc>.value(
      value: bloc,
      child: BlocBuilder<LiveTrackBloc, LiveTrackState>(
        builder: (context, state) {
          final activeShipments = state.filteredShipments;
          final selectedShipment = state.selectedShipment;

          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. Bilah Tab Atas (Kiriman Saya vs Paket Masuk)
                  LiveTrackTopBar(
                    selectedDirection: state.selectedDirection,
                    onDirectionChanged: (dir) {
                      bloc.add(LiveTrackDirectionChanged(dir));
                    },
                  ),

                  // 2. Bilah Filter Chip Status
                  LiveTrackFilterBar(
                    selectedStatus: state.selectedFilterStatus,
                    onStatusSelected: (status) {
                      bloc.add(LiveTrackFilterChanged(status));
                    },
                  ),

                  // 3. Peta Interaktif Layar Penuh
                  Expanded(
                    child: Stack(
                      children: [
                        // Lapisan Peta Beranimasi
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return LiveTrackMap(
                              isDark: isDark,
                              pulseValue: _pulseController.value,
                              zoomScale: state.zoomScale,
                              shipments: activeShipments,
                              selectedIndex: state.selectedIndex,
                              onShipmentTapped: (index) {
                                bloc.add(LiveTrackOrderSelected(index));
                              },
                            );
                          },
                        ),

                        // Pill Jumlah Kurir Aktif (Kiri Atas)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: LiveTrackStatusPill(
                            activeCourierCount: state.activeCourierCount,
                          ),
                        ),

                        // Kontrol Zoom & GPS (Kanan Atas)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: LiveTrackMapControls(
                            onZoomIn: () {
                              bloc.add(LiveTrackZoomChanged(
                                state.zoomScale + 0.15,
                              ));
                            },
                            onZoomOut: () {
                              bloc.add(LiveTrackZoomChanged(
                                state.zoomScale - 0.15,
                              ));
                            },
                            onCenter: () {
                              bloc.add(const LiveTrackResetCenter());
                            },
                          ),
                        ),

                        // Kartu Kurir Terpilih di Bagian Bawah
                        if (selectedShipment != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: LiveTrackCourierCard(
                              shipment: selectedShipment,
                            ),
                          ),

                        // Indikator Loading awal
                        if (state.isLoading && state.allShipments.isEmpty)
                          Positioned.fill(
                            child: Container(
                              color: (isDark
                                      ? AppColors.backgroundDark
                                      : AppColors.backgroundLight)
                                  .withValues(alpha: 0.6),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),

                        // Pesan kosong jika tidak ada kurir
                        if (!state.isLoading && activeShipments.isEmpty)
                          Positioned(
                            left: 24,
                            right: 24,
                            top: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? const Color(0xFF1B2A3D)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tidak ada pengiriman aktif pada filter ini.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
