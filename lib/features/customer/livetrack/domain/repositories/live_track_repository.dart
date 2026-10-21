import '../entities/live_track_shipment.dart';

abstract class LiveTrackRepository {
  /// Stream pembaruan posisi live kurir dan status pesanan secara real-time via Supabase Realtime
  Stream<List<LiveTrackShipment>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
    String? specificResi,
  });

  /// Mengambil daftar pesanan pelacakan aktif milik pelanggan yang sedang login
  Future<List<LiveTrackShipment>> getActiveTrackingOrders({
    required OrderDirection direction,
    String? specificResi,
  });

  /// Melacak detail pengiriman spesifik berdasarkan nomor resi atau barcode
  Future<LiveTrackShipment?> getShipmentByResi({
    required String resi,
  });
}
