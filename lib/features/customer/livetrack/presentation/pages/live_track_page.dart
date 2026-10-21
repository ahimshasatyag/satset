import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../data/datasources/live_track_local_datasource.dart';
import '../../data/datasources/live_track_remote_datasource.dart';
import '../../data/repositories/live_track_repository_impl.dart';
import '../../domain/entities/live_track_shipment.dart';
import '../../domain/usecases/get_live_tracking_orders_stream_usecase.dart';
import '../bloc/live_track_bloc.dart';
import '../bloc/live_track_event.dart';
import '../bloc/live_track_state.dart';
import '../widgets/live_track_courier_card.dart';
import '../widgets/live_track_empty_state.dart';
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
  final MapController _mapController = MapController();
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

        if (widget.initialDirection != null || widget.initialTrackingNumber != null) {
          _internalBloc!.add(
            LiveTrackStarted(
              initialDirection: widget.initialDirection,
              initialResi: widget.initialTrackingNumber,
            ),
          );
        }
      }
      return _internalBloc!;
    }
  }

  void _centerMapOnShipment(LiveTrackShipment? shipment, double currentZoom) {
    if (shipment == null) return;
    LatLng? targetPoint;
    if (shipment.isCourierGpsAvailable) {
      targetPoint = LatLng(shipment.courierLatitude!, shipment.courierLongitude!);
    } else if (shipment.hasDestinationCoordinates) {
      targetPoint = LatLng(shipment.receiverLatitude!, shipment.receiverLongitude!);
    } else if (shipment.senderLatitude != null && shipment.senderLongitude != null) {
      targetPoint = LatLng(shipment.senderLatitude!, shipment.senderLongitude!);
    }

    if (targetPoint != null) {
      _mapController.move(targetPoint, currentZoom.clamp(12.0, 17.0));
    }
  }

  void _showBarcodeDialog(BuildContext context, LiveTrackShipment shipment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Barcode Paket',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Ilustrasi visual barcode paket
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      // Baris garis barcode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(36, (index) {
                          final width = (index % 3 == 0) ? 3.5 : ((index % 2 == 0) ? 2.0 : 1.2);
                          final isSpace = index % 5 == 0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            width: width,
                            height: 60,
                            color: isSpace ? Colors.transparent : Colors.black,
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shipment.barcodeValue.isNotEmpty
                            ? shipment.barcodeValue
                            : shipment.trackingNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.black87,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Tunjukkan barcode ini kepada petugas kurir atau agen SatSet saat serah terima paket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: shipment.barcodeValue.isNotEmpty
                            ? shipment.barcodeValue
                            : shipment.trackingNumber,
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode barcode berhasil disalin!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Kode Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimelineDetailSheet(BuildContext context, LiveTrackShipment shipment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Gagang sheet
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header Sheet
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Perjalanan Paket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Resi: ${shipment.trackingNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Konten Scrollable
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Ringkasan Pengiriman
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.tertiary900 : AppColors.tertiary50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    shipment.serviceTypeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    shipment.statusName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pengirim: ${shipment.senderName} (${shipment.senderCity})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Penerima: ${shipment.receiverName} • ${shipment.receiverAddress}, ${shipment.receiverCity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              if (shipment.shippingNotes != null &&
                                  shipment.shippingNotes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Catatan: ${shipment.shippingNotes}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Timeline Pelacakan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Timeline items dari t_shipment_tracking
                        if (shipment.timeline.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Belum ada catatan jejak pelacakan untuk pengiriman ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Tampilkan riwayat secara kronologis (dari terbaru di atas ke terlama)
                          ...List.generate(shipment.timeline.length, (idx) {
                            final step = shipment.timeline[shipment.timeline.length - 1 - idx];
                            final isLatest = idx == 0;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kolom Garis & Dot
                                  Column(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isLatest
                                              ? AppColors.primary
                                              : (isDark
                                                  ? Colors.white24
                                                  : Colors.black26),
                                          border: isLatest
                                              ? Border.all(color: Colors.white, width: 2)
                                              : null,
                                        ),
                                      ),
                                      if (idx < shipment.timeline.length - 1)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.black12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Detail Event
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.statusName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isLatest
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isLatest
                                                  ? AppColors.primary
                                                  : (isDark
                                                      ? AppColors.textPrimaryDark
                                                      : AppColors.textPrimaryLight),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            step.notes,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                          if (step.locationName != null &&
                                              step.locationName!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.place_rounded,
                                                  size: 12,
                                                  color: AppColors.secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  step.locationName!,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: isDark
                                                        ? Colors.white60
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(step.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute WIB';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<LiveTrackBloc>.value(
      value: bloc,
      child: BlocConsumer<LiveTrackBloc, LiveTrackState>(
        listener: (context, state) {
          // Ketika shipment baru terpilih, pusatkan peta ke titiknya
          if (state.selectedShipment != null) {
            _centerMapOnShipment(state.selectedShipment, state.zoomScale);
          }
        },
        builder: (context, state) {
          final activeShipments = state.filteredShipments;
          final selectedShipment = state.selectedShipment;

          // Hitung jumlah pengiriman per status untuk badge filter bar
          final Map<OrderFilterStatus, int> filterCounts = {
            OrderFilterStatus.all: state.allShipments.length,
            OrderFilterStatus.waitingPickup: state.allShipments
                .where((s) => s.filterStatus == OrderFilterStatus.waitingPickup)
                .length,
            OrderFilterStatus.inDelivery: state.allShipments
                .where((s) => s.filterStatus == OrderFilterStatus.inDelivery)
                .length,
            OrderFilterStatus.completed: state.allShipments
                .where((s) => s.filterStatus == OrderFilterStatus.completed)
                .length,
          };

          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. Bilah Tab Atas (Kiriman Saya vs Paket Masuk) & Search Bar
                  LiveTrackTopBar(
                    selectedDirection: state.selectedDirection,
                    initialQuery: state.searchQuery,
                    onDirectionChanged: (dir) {
                      bloc.add(LiveTrackDirectionChanged(dir));
                    },
                    onSearchSubmitted: (query) {
                      bloc.add(LiveTrackSearchQueryChanged(query));
                    },
                    onRefresh: () {
                      bloc.add(const LiveTrackRefreshed());
                    },
                  ),

                  // 2. Bilah Filter Chip Status
                  LiveTrackFilterBar(
                    selectedStatus: state.selectedFilterStatus,
                    counts: filterCounts,
                    onStatusSelected: (status) {
                      bloc.add(LiveTrackFilterChanged(status));
                    },
                  ),

                  // 3. Area Peta Interaktif Layar Penuh
                  Expanded(
                    child: Stack(
                      children: [
                        // Peta OSM dengan FlutterMap
                        LiveTrackMap(
                          isDark: isDark,
                          pulseValue: _pulseController.value,
                          zoomScale: state.zoomScale,
                          shipments: activeShipments,
                          selectedIndex: state.selectedIndex,
                          mapController: _mapController,
                          onShipmentTapped: (index) {
                            bloc.add(LiveTrackOrderSelected(index));
                          },
                        ),

                        // Pill Status Kurir Aktif & Waktu Pembaruan (Kiri Atas)
                        Positioned(
                          top: 14,
                          left: 16,
                          child: LiveTrackStatusPill(
                            activeCourierCount: state.activeCourierCount,
                            isGpsAvailable: state.isSelectedGpsAvailable,
                            freshnessText:
                                selectedShipment?.locationFreshnessDescription ?? '',
                            isDisconnected:
                                state.errorMessage != null && activeShipments.isEmpty,
                            hasShipments: activeShipments.isNotEmpty,
                          ),
                        ),

                        // Kontrol Peta: Zoom & Pusatkan (Kanan Atas)
                        Positioned(
                          top: 14,
                          right: 16,
                          child: LiveTrackMapControls(
                            onZoomIn: () {
                              final newZoom = (state.zoomScale + 1.0).clamp(4.0, 18.0);
                              bloc.add(LiveTrackZoomChanged(newZoom));
                              _mapController.move(_mapController.camera.center, newZoom);
                            },
                            onZoomOut: () {
                              final newZoom = (state.zoomScale - 1.0).clamp(4.0, 18.0);
                              bloc.add(LiveTrackZoomChanged(newZoom));
                              _mapController.move(_mapController.camera.center, newZoom);
                            },
                            onCenter: () {
                              _centerMapOnShipment(selectedShipment, state.zoomScale);
                            },
                          ),
                        ),

                        // Kartu Kurir & Info Pengiriman Terpilih di Bagian Bawah
                        if (selectedShipment != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: LiveTrackCourierCard(
                              shipment: selectedShipment,
                              onViewBarcode: () =>
                                  _showBarcodeDialog(context, selectedShipment),
                              onViewDetails: () =>
                                  _showTimelineDetailSheet(context, selectedShipment),
                            ),
                          ),

                        // Indikator Loading Awal
                        if (state.isLoading && state.allShipments.isEmpty)
                          Positioned.fill(
                            child: Container(
                              color: (isDark
                                      ? AppColors.backgroundDark
                                      : AppColors.backgroundLight)
                                  .withValues(alpha: 0.65),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                        // Pesan Error jika Gagal Terhubung
                        if (state.errorMessage != null && state.allShipments.isEmpty)
                          Positioned(
                            left: 20,
                            right: 20,
                            top: 80,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.surfaceDark : Colors.white)
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.error),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      bloc.add(const LiveTrackRefreshed());
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Coba Lagi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Tampilan Data Kosong Berilustrasi Gambar jika Tidak Ada Pengiriman pada Filter
                        if (!state.isLoading &&
                            state.errorMessage == null &&
                            activeShipments.isEmpty)
                          Positioned.fill(
                            child: Container(
                              color: (isDark ? Colors.black : Colors.black)
                                  .withValues(alpha: isDark ? 0.45 : 0.18),
                              child: LiveTrackEmptyState(
                                direction: state.selectedDirection,
                                filterStatus: state.selectedFilterStatus,
                                searchQuery: state.searchQuery,
                                onRefresh: () {
                                  bloc.add(const LiveTrackRefreshed());
                                },
                                onResetFilter: () {
                                  bloc.add(const LiveTrackFilterChanged(
                                      OrderFilterStatus.all));
                                },
                                onClearSearch: () {
                                  bloc.add(const LiveTrackSearchQueryChanged(''));
                                },
                                onSwitchToOutgoing: () {
                                  bloc.add(const LiveTrackDirectionChanged(
                                      OrderDirection.outgoing));
                                },
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
