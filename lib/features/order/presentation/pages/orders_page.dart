import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_shipment.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_filter_chips_bar.dart';
import '../widgets/order_shipment_card.dart';

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
        final remote = OrderRemoteDataSourceImpl();
        final local = OrderLocalDataSourceImpl();
        final repo = OrderRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );
        _internalBloc = OrderBloc(
          getOrdersUseCase: GetOrdersUseCase(repo),
          createShipmentUseCase: CreateShipmentUseCase(repo),
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

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<OrderBloc>.value(
      value: bloc,
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                          ? const Center(
                              child: CustomLoading(
                                message: 'Memuat data pesanan...',
                              ),
                            )
                          : (state.orders.isEmpty
                              ? _buildEmptyState(isDark)
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 24),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada data pengiriman pada kategori filter yang Anda pilih saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
