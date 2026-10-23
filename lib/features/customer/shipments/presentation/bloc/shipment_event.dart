import 'package:equatable/equatable.dart';

abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

class ShipmentInitMasterDataRequested extends ShipmentEvent {
  const ShipmentInitMasterDataRequested();
}

class ShipmentCreateSubmitted extends ShipmentEvent {
  final Map<String, dynamic> payload;

  const ShipmentCreateSubmitted(this.payload);

  @override
  List<Object?> get props => [payload];
}

class ShipmentCreatedReset extends ShipmentEvent {
  const ShipmentCreatedReset();
}
