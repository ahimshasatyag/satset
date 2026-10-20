import 'package:equatable/equatable.dart';
import '../../domain/entities/order_shipment.dart';

class OrderState extends Equatable {
  final OrderDirection selectedDirection;
  final OrderFilterStatus selectedFilterStatus;
  final List<OrderShipment> orders;
  final bool isLoading;
  final String? message;

  const OrderState({
    this.selectedDirection = OrderDirection.outgoing,
    this.selectedFilterStatus = OrderFilterStatus.all,
    this.orders = const [],
    this.isLoading = true,
    this.message,
  });

  OrderState copyWith({
    OrderDirection? selectedDirection,
    OrderFilterStatus? selectedFilterStatus,
    List<OrderShipment>? orders,
    bool? isLoading,
    String? message,
  }) {
    return OrderState(
      selectedDirection: selectedDirection ?? this.selectedDirection,
      selectedFilterStatus:
          selectedFilterStatus ?? this.selectedFilterStatus,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        selectedDirection,
        selectedFilterStatus,
        orders,
        isLoading,
        message,
      ];
}
