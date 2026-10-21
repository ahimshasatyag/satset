import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_shipment.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import 'package:satset/features/shipments/presentation/widgets/create_shipment_sheet.dart';
import '../widgets/order_filter_chips_bar.dart';
import '../widgets/order_shipment_card.dart';
import '../widgets/orders_skeleton.dart';
import 'payment_page.dart';

class OrdersPage extends StatefulWidget {
  final OrderDirection? initialDirection;
  final OrderFilterStatus? initialFilter;

  const OrdersPage({
    super.key,
    this.initialDirection,
    this.initialFilter,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  OrderBloc? _internalBloc;
  late final OrderRepository _repository;

  @override
  void initState() {
    super.initState();
    final remote = OrderRemoteDataSourceImpl();
    final local = OrderLocalDataSourceImpl();
    _repository = OrderRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  }

  @override
  void dispose() {
    _internalBloc?.close();
    super.dispose();
  }

  OrderBloc _getOrCreateBloc(BuildContext context) {
    try {
      return BlocProvider.of<OrderBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        _internalBloc = OrderBloc(
          getOrdersUseCase: GetOrdersUseCase(_repository),
          createShipmentUseCase: CreateShipmentUseCase(_repository),
          repository: _repository,
        );
        if (widget.initialDirection != null || widget.initialFilter != null) {
          _internalBloc!.add(OrderFilterChanged(
            direction: widget.initialDirection,
            filterStatus: widget.initialFilter,
          ));
        }
      }
      return _internalBloc!;
    }
  }

  void _openCreateShipmentModal(OrderBloc bloc) {
    CreateShipmentSheet.show(
      context,
      repository: _repository,
      onOrderCreated: (orderData) {
        bloc.add(OrderCreateSubmitted(orderData));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<OrderBloc>.value(
      value: bloc,
      child: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state.createdShipment != null) {
            final shipment = state.createdShipment!;
            bloc.add(const OrderCreatedReset());
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaymentPage(order: shipment),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Coba Lagi',
                  textColor: Colors.white,
                  onPressed: () => bloc.add(const OrderRefreshed()),
                ),
              ),
            );
          } else if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openCreateShipmentModal(bloc),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Kirim Paket',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Top TabBar (Kiriman Saya vs Paket Masuk)
                  _buildTopTabBar(
                    isDark: isDark,
                    selectedDirection: state.selectedDirection,
                    onDirectionChanged: (dir) {
                      bloc.add(OrderFilterChanged(direction: dir));
                    },
                  ),

                  // 2. Filter Chips Bar (Semua, Menunggu Penjemputan, Sedang Diantar, Selesai)
                  OrderFilterChipsBar(
                    selectedStatus: state.selectedFilterStatus,
                    onStatusSelected: (status) {
                      bloc.add(OrderFilterChanged(filterStatus: status));
                    },
                  ),

                  // 3. Daftar Pesanan
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        bloc.add(const OrderRefreshed());
                      },
                      child: state.isLoading
                          ? const OrdersSkeleton()
                          : (state.orders.isEmpty
                              ? _buildEmptyState(isDark, bloc)
                              : ListView.separated(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 84),
                                  itemCount: state.orders.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final order = state.orders[index];
                                    return OrderShipmentCard(order: order);
                                  },
                                )),
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

  Widget _buildTopTabBar({
    required bool isDark,
    required OrderDirection selectedDirection,
    required ValueChanged<OrderDirection> onDirectionChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTopTabItem(
            direction: OrderDirection.outgoing,
            icon: Icons.outbox_rounded,
            label: 'Kiriman Saya',
            isSelected: selectedDirection == OrderDirection.outgoing,
            isDark: isDark,
            onTap: () => onDirectionChanged(OrderDirection.outgoing),
          ),
          _buildTopTabItem(
            direction: OrderDirection.incoming,
            icon: Icons.move_to_inbox_rounded,
            label: 'Paket Masuk',
            isSelected: selectedDirection == OrderDirection.incoming,
            isDark: isDark,
            onTap: () => onDirectionChanged(OrderDirection.incoming),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem({
    required OrderDirection direction,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, OrderBloc bloc) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Belum Ada Pesanan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tidak ada pengiriman pada kategori filter yang Anda pilih saat ini.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _openCreateShipmentModal(bloc),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Kiriman Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
