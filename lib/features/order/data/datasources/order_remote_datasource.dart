import 'dart:async';
import '../../domain/entities/order_shipment.dart';
import '../models/order_shipment_model.dart';

abstract class OrderRemoteDataSource {
  Stream<int> getActiveOrdersCountStream();

  Future<List<OrderShipmentModel>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  });

  Future<void> createShipmentOrder(Map<String, dynamic> data);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  StreamController<int>? _activeCountController;

  static final List<OrderShipmentModel> _allOrders = [
    // 1. Kiriman Saya (Outgoing) - Sedang Diantar
    OrderShipmentModel(
      id: 'ord-out-01',
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
      etaMinutes: 12,
      distanceKm: 1.8,
      price: 24000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      updatedAt: DateTime.now(),
    ),
    // 2. Kiriman Saya (Outgoing) - Menunggu Penjemputan
    OrderShipmentModel(
      id: 'ord-out-02',
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
      etaMinutes: 25,
      distanceKm: 4.2,
      price: 18000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now(),
    ),
    // 3. Kiriman Saya (Outgoing) - Selesai
    OrderShipmentModel(
      id: 'ord-out-03',
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
      statusDescription: 'Paket telah diterima langsung oleh studio',
      courierName: 'Rian Hidayat',
      courierPhone: '+628567890123',
      courierVehicle: 'B 4120 SAT (Vespa Matic)',
      etaMinutes: 0,
      distanceKm: 0.0,
      price: 35000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // 4. Paket Masuk (Incoming) - Sedang Diantar
    OrderShipmentModel(
      id: 'ord-in-01',
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
      etaMinutes: 14,
      distanceKm: 2.1,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now(),
    ),
    // 5. Paket Masuk (Incoming) - Menunggu Penjemputan dari Toko
    OrderShipmentModel(
      id: 'ord-in-02',
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
      etaMinutes: 120,
      distanceKm: 140.0,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now(),
    ),
    // 6. Paket Masuk (Incoming) - Selesai
    OrderShipmentModel(
      id: 'ord-in-03',
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
      etaMinutes: 0,
      distanceKm: 0.0,
      price: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Stream<int> getActiveOrdersCountStream() {
    _activeCountController?.close();
    _activeCountController = StreamController<int>.broadcast(
      onListen: () {
        final activeCount = _allOrders.where((o) => o.isActive).length;
        _activeCountController?.add(activeCount);
      },
    );
    return _activeCountController!.stream;
  }

  @override
  Future<List<OrderShipmentModel>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _allOrders.where((item) {
      final matchDirection = item.direction == direction;
      final matchFilter =
          filter == OrderFilterStatus.all || item.filterStatus == filter;
      return matchDirection && matchFilter;
    }).toList();
  }

  @override
  Future<void> createShipmentOrder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newOrder = OrderShipmentModel(
      id: 'ord-out-${DateTime.now().millisecondsSinceEpoch}',
      trackingNumber:
          'SS-OUT-${(1000 + DateTime.now().millisecond).toString()}',
      itemName: data['itemName'] as String? ?? 'Paket Baru SatSet',
      itemCategory: data['itemCategory'] as String? ?? 'Reguler',
      serviceType: data['serviceType'] as String? ?? 'SATSET Instant',
      direction: OrderDirection.outgoing,
      filterStatus: OrderFilterStatus.waitingPickup,
      senderName: 'Satria Perkasa (Saya)',
      receiverName: data['receiverName'] as String? ?? 'Penerima SatSet',
      originCity: 'Jakarta Selatan',
      destinationCity: data['destinationCity'] as String? ?? 'Jakarta Barat',
      statusDescription: 'Pesanan dibuat. Menunggu penjemputan kurir.',
      courierName: 'Mencari Kurir Terdekat...',
      courierPhone: '-',
      courierVehicle: 'SatSet Fleet',
      etaMinutes: 20,
      distanceKm: 3.5,
      price: data['price'] as int? ?? 20000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _allOrders.insert(0, newOrder);
    _activeCountController?.add(_allOrders.where((o) => o.isActive).length);
  }
}
