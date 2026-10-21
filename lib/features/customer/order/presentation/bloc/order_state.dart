import 'package:equatable/equatable.dart';
import '../../domain/entities/order_shipment.dart';

class OrderState extends Equatable {
  final OrderDirection selectedDirection;
  final OrderFilterStatus selectedFilterStatus;
  final List<OrderShipment> orders;
  final bool isLoading;
  final bool isSubmitting;
  final bool isVerifyingPayment;
  final OrderShipment? createdShipment;
  final ShipmentPayment? activePayment;
  final String? message;
  final String? errorMessage;

  const OrderState({
    this.selectedDirection = OrderDirection.outgoing,
    this.selectedFilterStatus = OrderFilterStatus.all,
    this.orders = const [],
    this.isLoading = true,
    this.isSubmitting = false,
    this.isVerifyingPayment = false,
    this.createdShipment,
    this.activePayment,
    this.message,
    this.errorMessage,
  });

  OrderState copyWith({
    OrderDirection? selectedDirection,
    OrderFilterStatus? selectedFilterStatus,
    List<OrderShipment>? orders,
    bool? isLoading,
    bool? isSubmitting,
    bool? isVerifyingPayment,
    OrderShipment? createdShipment,
    ShipmentPayment? activePayment,
    String? message,
    String? errorMessage,
    bool clearCreatedShipment = false,
  }) {
    return OrderState(
      selectedDirection: selectedDirection ?? this.selectedDirection,
      selectedFilterStatus: selectedFilterStatus ?? this.selectedFilterStatus,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isVerifyingPayment: isVerifyingPayment ?? this.isVerifyingPayment,
      createdShipment: clearCreatedShipment
          ? null
          : (createdShipment ?? this.createdShipment),
      activePayment: activePayment ?? this.activePayment,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedDirection,
        selectedFilterStatus,
        orders,
        isLoading,
        isSubmitting,
        isVerifyingPayment,
        createdShipment,
        activePayment,
        message,
        errorMessage,
      ];
}
