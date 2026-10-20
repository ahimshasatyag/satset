import 'package:equatable/equatable.dart';
import '../../domain/entities/order_shipment.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Permintaan pemuatan awal daftar pesanan
class OrderListRequested extends OrderEvent {
  const OrderListRequested();
}

/// Pengguna mengubah arah (Kiriman Saya vs Paket Masuk) atau filter status
class OrderFilterChanged extends OrderEvent {
  final OrderDirection? direction;
  final OrderFilterStatus? filterStatus;

  const OrderFilterChanged({this.direction, this.filterStatus});

  @override
  List<Object?> get props => [direction, filterStatus];
}

/// Pengguna membuat pesanan pengiriman baru via modal "+ Kirim"
class OrderCreateSubmitted extends OrderEvent {
  final Map<String, dynamic> orderData;

  const OrderCreateSubmitted(this.orderData);

  @override
  List<Object?> get props => [orderData];
}

/// Pengguna memicu pull-to-refresh
class OrderRefreshed extends OrderEvent {
  const OrderRefreshed();
}
