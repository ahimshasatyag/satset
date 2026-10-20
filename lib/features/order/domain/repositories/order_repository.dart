import '../entities/order_shipment.dart';

abstract class OrderRepository {
  /// Mengambil daftar pesanan berdasarkan arah (Kiriman Saya / Paket Masuk) dan filter
  Future<List<OrderShipment>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  });

  /// Stream jumlah paket aktif yang sedang berjalan untuk lencana (badge) menu Pesanan
  Stream<int> getActiveOrdersCountStream();

  /// Membuat pesanan pengiriman baru via tombol "+ Kirim"
  Future<void> createShipmentOrder(Map<String, dynamic> data);
}
