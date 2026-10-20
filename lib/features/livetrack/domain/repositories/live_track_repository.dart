import '../entities/live_track_shipment.dart';

abstract class LiveTrackRepository {
  /// Stream pembaruan posisi live kurir dan status pesanan secara real-time
  Stream<List<LiveTrackShipment>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
  });

  /// Mengambil daftar pesanan pelacakan aktif
  Future<List<LiveTrackShipment>> getActiveTrackingOrders({
    required OrderDirection direction,
  });
}
