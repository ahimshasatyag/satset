import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_shipment.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrdersUseCase getOrdersUseCase;
  final CreateShipmentUseCase createShipmentUseCase;

  OrderBloc({
    required this.getOrdersUseCase,
    required this.createShipmentUseCase,
  }) : super(const OrderState()) {
    on<OrderListRequested>(_onListRequested);
    on<OrderFilterChanged>(_onFilterChanged);
    on<OrderCreateSubmitted>(_onCreateSubmitted);
    on<OrderRefreshed>(_onRefreshed);

    add(const OrderListRequested());
  }

  Future<void> _onListRequested(
    OrderListRequested event,
    Emitter<OrderState> emit,
  ) async {
    await _loadOrders(state.selectedDirection, state.selectedFilterStatus, emit);
  }

  Future<void> _loadOrders(
    OrderDirection direction,
    OrderFilterStatus filterStatus,
    Emitter<OrderState> emit,
  ) async {
    try {
      final list = await getOrdersUseCase(
        direction: direction,
        filter: filterStatus,
      );
      emit(state.copyWith(
        orders: list,
        selectedDirection: direction,
        selectedFilterStatus: filterStatus,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        message: 'Gagal memuat daftar pesanan: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFilterChanged(
    OrderFilterChanged event,
    Emitter<OrderState> emit,
  ) async {
    final dir = event.direction ?? state.selectedDirection;
    final flt = event.filterStatus ?? state.selectedFilterStatus;
    emit(state.copyWith(isLoading: true));
    await _loadOrders(dir, flt, emit);
  }

  Future<void> _onRefreshed(
    OrderRefreshed event,
    Emitter<OrderState> emit,
  ) async {
    await _loadOrders(state.selectedDirection, state.selectedFilterStatus, emit);
  }

  Future<void> _onCreateSubmitted(
    OrderCreateSubmitted event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await createShipmentUseCase(event.orderData);
      emit(state.copyWith(
        message: 'Pesanan pengiriman berhasil dibuat!',
        selectedDirection: OrderDirection.outgoing,
      ));
      await _loadOrders(OrderDirection.outgoing, OrderFilterStatus.all, emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        message: 'Gagal membuat pesanan: ${e.toString()}',
      ));
    }
  }
}
