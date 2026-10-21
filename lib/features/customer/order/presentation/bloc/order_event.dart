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

/// Pengguna membuat pesanan pengiriman baru
class OrderCreateSubmitted extends OrderEvent {
  final Map<String, dynamic> orderData;

  const OrderCreateSubmitted(this.orderData);

  @override
  List<Object?> get props => [orderData];
}

/// Pengguna memverifikasi status pembayaran transaksi di backend
class OrderPaymentVerifyRequested extends OrderEvent {
  final String shipmentId;

  const OrderPaymentVerifyRequested(this.shipmentId);

  @override
  List<Object?> get props => [shipmentId];
}

/// Pembaruan status pembayaran real-time dari Supabase
class OrderPaymentStatusUpdated extends OrderEvent {
  final ShipmentPayment? payment;

  const OrderPaymentStatusUpdated(this.payment);

  @override
  List<Object?> get props => [payment];
}

/// Reset state pengiriman yang baru dibuat setelah proses navigasi selesai
class OrderCreatedReset extends OrderEvent {
  const OrderCreatedReset();
}

/// Pengguna memicu pull-to-refresh
class OrderRefreshed extends OrderEvent {
  const OrderRefreshed();
}
