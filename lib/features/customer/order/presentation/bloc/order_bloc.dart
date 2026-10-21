import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_shipment.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrdersUseCase getOrdersUseCase;
  final CreateShipmentUseCase createShipmentUseCase;
  final OrderRepository? repository;

  StreamSubscription<ShipmentPayment?>? _paymentSub;

  OrderBloc({
    required this.getOrdersUseCase,
    required this.createShipmentUseCase,
    this.repository,
  }) : super(const OrderState()) {
    on<OrderListRequested>(_onListRequested);
    on<OrderFilterChanged>(_onFilterChanged);
    on<OrderCreateSubmitted>(_onCreateSubmitted);
    on<OrderPaymentVerifyRequested>(_onPaymentVerifyRequested);
    on<OrderPaymentStatusUpdated>(_onPaymentStatusUpdated);
    on<OrderCreatedReset>(_onCreatedReset);
    on<OrderRefreshed>(_onRefreshed);

    add(const OrderListRequested());
  }

  OrderRepository get _repo => repository ?? createShipmentUseCase.repository;

  @override
  Future<void> close() {
    _paymentSub?.cancel();
    return super.close();
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
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar pesanan: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFilterChanged(
    OrderFilterChanged event,
    Emitter<OrderState> emit,
  ) async {
    final dir = event.direction ?? state.selectedDirection;
    final flt = event.filterStatus ?? state.selectedFilterStatus;
    emit(state.copyWith(isLoading: true, errorMessage: null));
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
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final createdShipment = await createShipmentUseCase(event.orderData);

      // Mulai dengarkan pembaruan payment real-time untuk shipment ini
      _subscribePaymentRealtime(createdShipment.id);

      emit(state.copyWith(
        isSubmitting: false,
        createdShipment: createdShipment,
        activePayment: createdShipment.payment,
        message: 'Pesanan #${createdShipment.trackingNumber} berhasil dibuat!',
        selectedDirection: OrderDirection.outgoing,
      ));

      // Reload order list di background
      await _loadOrders(OrderDirection.outgoing, OrderFilterStatus.all, emit);
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal membuat pesanan: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPaymentVerifyRequested(
    OrderPaymentVerifyRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isVerifyingPayment: true, errorMessage: null));
    try {
      final payment = await _repo.verifyPaymentStatus(event.shipmentId);
      final isPaid = payment?.isPaid == true;

      // Update state order yang bersangkutan di list
      final updatedOrders = state.orders.map((o) {
        if (o.id == event.shipmentId && payment != null) {
          return o.copyWith(
            payment: payment,
            statusCode: isPaid ? 'CONFIRMED' : o.statusCode,
          );
        }
        return o;
      }).toList();

      emit(state.copyWith(
        isVerifyingPayment: false,
        activePayment: payment,
        orders: updatedOrders,
        message: isPaid
            ? 'Pembayaran berhasil diverifikasi!'
            : (payment != null
                ? 'Status saat ini: ${payment.status.label}'
                : 'Pembayaran belum tercatat di sistem.'),
      ));
    } catch (e) {
      emit(state.copyWith(
        isVerifyingPayment: false,
        errorMessage: 'Gagal memverifikasi pembayaran: $e',
      ));
    }
  }

  void _onPaymentStatusUpdated(
    OrderPaymentStatusUpdated event,
    Emitter<OrderState> emit,
  ) {
    if (event.payment == null) return;
    final payment = event.payment!;
    final isPaid = payment.isPaid;

    final updatedOrders = state.orders.map((o) {
      if (o.id == payment.shipmentId.toString()) {
        return o.copyWith(
          payment: payment,
          statusCode: isPaid ? 'CONFIRMED' : o.statusCode,
        );
      }
      return o;
    }).toList();

    emit(state.copyWith(
      activePayment: payment,
      orders: updatedOrders,
      message: isPaid ? 'Pembayaran berhasil dikonfirmasi secara real-time!' : null,
    ));
  }

  void _onCreatedReset(
    OrderCreatedReset event,
    Emitter<OrderState> emit,
  ) {
    emit(state.copyWith(clearCreatedShipment: true));
  }

  void _subscribePaymentRealtime(String shipmentId) {
    _paymentSub?.cancel();
    _paymentSub = _repo.streamPaymentStatus(shipmentId).listen(
      (payment) {
        if (payment != null && !isClosed) {
          add(OrderPaymentStatusUpdated(payment));
        }
      },
    );
  }
}
