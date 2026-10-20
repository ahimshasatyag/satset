import 'dart:async';
import '../../domain/entities/live_track_shipment.dart';
import '../models/live_track_shipment_model.dart';

abstract class LiveTrackRemoteDataSource {
  /// Stream data pembaruan posisi live kurir & ETA
  Stream<List<LiveTrackShipmentModel>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
  });

  /// Mengambil daftar pesanan pelacakan aktif saat ini
  Future<List<LiveTrackShipmentModel>> getActiveTrackingOrders({
    required OrderDirection direction,
  });
}

class LiveTrackRemoteDataSourceImpl implements LiveTrackRemoteDataSource {
  StreamController<List<LiveTrackShipmentModel>>? _liveTrackingController;
  Timer? _liveMovementTimer;
  int _simulationTick = 0;

  static final List<LiveTrackShipmentModel> _mockShipments = [
    // 1. Kiriman Saya (Outgoing) - Sedang Diantar
    LiveTrackShipmentModel(
      id: 'trk-out-01',
      trackingNumber: 'SS-OUT-8812',
      itemName: 'Dokumen Perjanjian Kerjasama Notaris',
      itemCategory: 'Dokumen',
      serviceType: 'SATSET Instant',
      direction: OrderDirection.outgoing,
      filterStatus: OrderFilterStatus.inDelivery,
      senderName: 'Satria Perkasa (Saya)',
      receiverName: 'PT Mega Cipta Pratama',
      originCity: 'Jakarta Selatan',
      destinationCity: 'SCBD, Jakarta Selatan',
      statusDescription: 'Kurir sedang dalam perjalanan ke alamat tujuan',
      courierName: 'Doni Pratama',
      courierPhone: '+628123456789',
      courierVehicle: 'B 3144 SAT (Honda Beat)',
      latitude: -6.2270,
      longitude: 106.8120,
      etaMinutes: 12,
      distanceKm: 1.8,
      price: 24000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      updatedAt: DateTime.now(),
    ),
    // 2. Kiriman Saya (Outgoing) - Menunggu Penjemputan
    LiveTrackShipmentModel(
      id: 'trk-out-02',
      trackingNumber: 'SS-OUT-5419',
      itemName: 'Hampers Kue Lebaran Premium',
      itemCategory: 'Makanan',
      serviceType: 'SATSET Sameday',
      direction: OrderDirection.outgoing,
      filterStatus: OrderFilterStatus.waitingPickup,
      senderName: 'Satria Perkasa (Saya)',
      receiverName: 'Bunda Rini',
      originCity: 'Kebayoran Baru',
      destinationCity: 'Bintaro Jaya, Tangerang Selatan',
      statusDescription: 'Kurir menuju lokasi penjemputan Anda',
      courierName: 'Agus Santoso',
      courierPhone: '+628198765432',
      courierVehicle: 'B 6922 SAT (Yamaha NMAX)',
      latitude: -6.2440,
      longitude: 106.7950,
      etaMinutes: 25,
      distanceKm: 4.2,
      price: 18000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now(),
    ),
    // 3. Kiriman Saya (Outgoing) - Selesai
    LiveTrackShipmentModel(
      id: 'trk-out-03',
      trackingNumber: 'SS-OUT-1024',
      itemName: 'Kamera Mirrorless Sony A7IV',
      itemCategory: 'Elektronik',
      serviceType: 'SATSET Instant',
      direction: OrderDirection.outgoing,
      filterStatus: OrderFilterStatus.completed,
      senderName: 'Satria Perkasa (Saya)',
      receiverName: 'Studio Foto Abadi',
      originCity: 'Jakarta Selatan',
      destinationCity: 'Kemang, Jakarta Selatan',
      statusDescription: 'Paket telah diterima langsung oleh penerima',
      courierName: 'Rian Hidayat',
      courierPhone: '+628567890123',
      courierVehicle: 'B 4120 SAT (Vespa Matic)',
      latitude: -6.2620,
      longitude: 106.8150,
      etaMinutes: 0,
      distanceKm: 0.0,
      price: 35000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // 4. Paket Masuk (Incoming) - Sedang Diantar
    LiveTrackShipmentModel(
      id: 'trk-in-01',
      trackingNumber: 'SS-98214-ID',
      itemName: 'MacBook Pro M3 & Magic Mouse',
      itemCategory: 'Elektronik & Gadget',
      serviceType: 'SATSET Instant',
      direction: OrderDirection.incoming,
      filterStatus: OrderFilterStatus.inDelivery,
      senderName: 'Warehouse Mega Kuningan',
      receiverName: 'Satria Perkasa (Saya)',
      originCity: 'Karet Kuningan, Jakarta Selatan',
      destinationCity: 'Kebayoran Baru, Jakarta Selatan',
      statusDescription: 'Kurir berjarak 2.1 km dari rumah Anda',
      courierName: 'Bambang Supriyanto',
      courierPhone: '+6281298765432',
      courierVehicle: 'B 4912 SAT (Honda Vario)',
      latitude: -6.2290,
      longitude: 106.8180,
      etaMinutes: 14,
      distanceKm: 2.1,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now(),
    ),
    // 5. Paket Masuk (Incoming) - Menunggu Penjemputan dari Toko
    LiveTrackShipmentModel(
      id: 'trk-in-02',
      trackingNumber: 'SS-IN-3329',
      itemName: 'Sepatu Boots Kulit Vintage',
      itemCategory: 'Fashion',
      serviceType: 'SATSET Reguler',
      direction: OrderDirection.incoming,
      filterStatus: OrderFilterStatus.waitingPickup,
      senderName: 'Brodo Official Store Bandung',
      receiverName: 'Satria Perkasa (Saya)',
      originCity: 'Bandung',
      destinationCity: 'Jakarta Selatan',
      statusDescription: 'Menunggu paket diserahkan ke agen SatSet',
      courierName: 'Mitra Hub SatSet',
      courierPhone: '+62811223344',
      courierVehicle: 'Mobil Box L300',
      latitude: -6.2380,
      longitude: 106.8040,
      etaMinutes: 45,
      distanceKm: 6.5,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now(),
    ),
    // 6. Paket Masuk (Incoming) - Selesai
    LiveTrackShipmentModel(
      id: 'trk-in-03',
      trackingNumber: 'SS-76219-ID',
      itemName: 'Sepatu Lari Nike Air Zoom',
      itemCategory: 'Olahraga',
      serviceType: 'SATSET Sameday',
      direction: OrderDirection.incoming,
      filterStatus: OrderFilterStatus.completed,
      senderName: 'Nike Grand Indonesia',
      receiverName: 'Satria Perkasa (Saya)',
      originCity: 'Jakarta Pusat',
      destinationCity: 'Jakarta Selatan',
      statusDescription: 'Telah diterima di resepsionis',
      courierName: 'Tono Sutrisno',
      courierPhone: '+6287711223344',
      courierVehicle: 'B 5519 SAT',
      latitude: -6.2260,
      longitude: 106.8080,
      etaMinutes: 0,
      distanceKm: 0.0,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<LiveTrackShipmentModel>> getActiveTrackingOrders({
    required OrderDirection direction,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockShipments
        .where((item) => item.direction == direction)
        .toList();
  }

  @override
  Stream<List<LiveTrackShipmentModel>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
  }) {
    _stopLiveTrackingLoop();
    _liveTrackingController?.close();

    _liveTrackingController =
        StreamController<List<LiveTrackShipmentModel>>.broadcast(
      onListen: () => _startLiveTrackingLoop(direction),
      onCancel: _stopLiveTrackingLoop,
    );

    return _liveTrackingController!.stream;
  }

  void _startLiveTrackingLoop(OrderDirection direction) {
    void emitUpdatedOrders() {
      if (_liveTrackingController == null || _liveTrackingController!.isClosed) {
        return;
      }
      _simulationTick++;

      final activeList = _mockShipments.where((item) {
        return item.direction == direction;
      }).map((item) {
        if (item.filterStatus != OrderFilterStatus.inDelivery) {
          return item;
        }

        // Simulasi pergerakan titik koordinat kurir di jalan
        final latOffset = ((_simulationTick % 6) - 2.5) * 0.0008;
        final lngOffset = ((_simulationTick % 8) - 3.5) * 0.0011;
        final updatedEta = (item.etaMinutes - (_simulationTick % 3)).clamp(3, 45);

        return item.copyWith(
          latitude: item.latitude + latOffset,
          longitude: item.longitude + lngOffset,
          etaMinutes: updatedEta,
          updatedAt: DateTime.now(),
        );
      }).toList();

      _liveTrackingController?.add(activeList);
    }

    emitUpdatedOrders();
    _liveMovementTimer?.cancel();
    _liveMovementTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => emitUpdatedOrders());
  }

  void _stopLiveTrackingLoop() {
    _liveMovementTimer?.cancel();
    _liveMovementTimer = null;
  }
}
