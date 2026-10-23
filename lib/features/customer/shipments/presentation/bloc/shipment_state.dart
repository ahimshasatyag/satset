import 'package:equatable/equatable.dart';
import '../../domain/entities/shipment.dart';

class ShipmentState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final List<Province> provinces;
  final List<OrderServiceType> serviceTypes;
  final OrderShipment? createdShipment;
  final String? errorMessage;
  final String? successMessage;

  const ShipmentState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.provinces = const [],
    this.serviceTypes = const [],
    this.createdShipment,
    this.errorMessage,
    this.successMessage,
  });

  ShipmentState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<Province>? provinces,
    List<OrderServiceType>? serviceTypes,
    OrderShipment? createdShipment,
    String? errorMessage,
    String? successMessage,
    bool clearCreatedShipment = false,
  }) {
    return ShipmentState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      provinces: provinces ?? this.provinces,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      createdShipment: clearCreatedShipment
          ? null
          : (createdShipment ?? this.createdShipment),
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        provinces,
        serviceTypes,
        createdShipment,
        errorMessage,
        successMessage,
      ];
}
