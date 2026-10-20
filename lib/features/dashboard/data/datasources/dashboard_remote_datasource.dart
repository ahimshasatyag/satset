import 'dart:async';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/shipment.dart';
import '../models/courier_model.dart';
import '../models/location_point_model.dart';
import '../models/shipment_model.dart';
import '../models/user_profile_model.dart';

abstract class DashboardRemoteDataSource {
  /// Stream real-time aktif (simulasi WebSocket / Firestore Snapshot)
  Stream<ShipmentModel> getLiveActiveShipmentStream();

  Future<ShipmentModel> getActiveShipment();

  Future<List<ShipmentModel>> getRecentShipments();

  Future<ShipmentModel?> trackShipment(String trackingNumber);

  Future<UserProfileModel> getUserProfile();

  Future<void> markNotificationsAsRead();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final String? authToken;
  final User? currentUser;

  DashboardRemoteDataSourceImpl({
    this.authToken,
    this.currentUser,
  });

  StreamController<ShipmentModel>? _streamController;
  Timer? _realtimeSimulationTimer;
  ShipmentModel _currentActiveShipment = _initialActiveShipment;
  int _simulationStep = 0;

  static final ShipmentModel _initialActiveShipment = ShipmentModel(
    id: 'shp-001',
    trackingNumber: 'SS-98214-ID',
    itemName: 'MacBook Pro M3 & Magic Mouse',
    itemCategory: 'Elektronik & Gadget',
    serviceType: 'SATSET Instant',
    status: ShipmentStatus.outForDelivery,
    origin: const LocationPointModel(
      name: 'Warehouse SatSet Mega Kuningan',
      address: 'Jl. Prof. DR. Satrio No.18, RT.4/RW.4, Karet Kuningan',
      city: 'Jakarta Selatan',
      latitude: -6.2238,
      longitude: 106.8285,
    ),
    destination: const LocationPointModel(
      name: 'Rumah (Satria Perkasa)',
      address: 'Jl. Senopati No. 42, Selong, Kebayoran Baru',
      city: 'Jakarta Selatan',
      latitude: -6.2341,
      longitude: 106.8093,
    ),
    courier: const CourierModel(
      id: 'cr-8821',
      name: 'Bambang Supriyanto',
      phone: '+6281298765432',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      vehicleType: 'Honda Vario 160 (SatSet Flash)',
      vehiclePlate: 'B 4912 SAT',
      rating: 4.95,
      latitude: -6.2290,
      longitude: 106.8180,
    ),
    courierPosition: const LocationPointModel(
      name: 'Posisi Kurir Saat Ini',
      address: 'Mendekati Jl. Gunawarman, Kebayoran Baru',
      city: 'Jakarta Selatan',
      latitude: -6.2290,
      longitude: 106.8180,
    ),
    etaMinutes: 14,
    distanceKm: 2.1,
    updatedAt: DateTime.now(),
    timeline: [
      ShipmentTimelineStepModel(
        title: 'Pesanan Dikonfirmasi',
        description: 'Paket telah siap di Warehouse Mega Kuningan',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isCompleted: true,
      ),
      ShipmentTimelineStepModel(
        title: 'Paket Dijemput (Picked Up)',
        description: 'Kurir Bambang telah mengambil paket',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isCompleted: true,
      ),
      ShipmentTimelineStepModel(
        title: 'Dalam Perjalanan (In Transit)',
        description: 'Paket melintasi Jl. Rasuna Said menuju Kebayoran Baru',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        isCompleted: true,
      ),
      ShipmentTimelineStepModel(
        title: 'Kurir Menuju Lokasi (Out for Delivery)',
        description: 'Kurir berada 2.1 km dari tujuan. Harap siapkan penerima.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isCompleted: false,
        isCurrent: true,
      ),
    ],
  );

  static final List<ShipmentModel> _recentShipmentsMock = [
    ShipmentModel(
      id: 'shp-002',
      trackingNumber: 'SS-76219-ID',
      itemName: 'Sepatu Lari Nike Air Zoom',
      itemCategory: 'Fashion & Olahraga',
      serviceType: 'SATSET Sameday',
      status: ShipmentStatus.delivered,
      origin: const LocationPointModel(
        name: 'Official Store Grand Indonesia',
        address: 'Jl. M.H. Thamrin No.1',
        city: 'Jakarta Pusat',
        latitude: -6.1950,
        longitude: 106.8230,
      ),
      destination: const LocationPointModel(
        name: 'Kantor Satria Perkasa',
        address: 'Pacific Century Place Lt. 12, SCBD',
        city: 'Jakarta Selatan',
        latitude: -6.2260,
        longitude: 106.8080,
      ),
      courierPosition: const LocationPointModel(
        name: 'Telah Diterima',
        address: 'Resepsionis Lt. 12',
        city: 'Jakarta Selatan',
        latitude: -6.2260,
        longitude: 106.8080,
      ),
      etaMinutes: 0,
      distanceKm: 0.0,
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      timeline: const [],
    ),
    ShipmentModel(
      id: 'shp-003',
      trackingNumber: 'SS-54120-ID',
      itemName: 'Kopi Arabika Toraja 1kg & Filter V60',
      itemCategory: 'Makanan & Minuman',
      serviceType: 'SATSET Reguler',
      status: ShipmentStatus.delivered,
      origin: const LocationPointModel(
        name: 'Roastery SatSet Bandung',
        address: 'Jl. Riau No. 45',
        city: 'Bandung',
        latitude: -6.9080,
        longitude: 107.6180,
      ),
      destination: const LocationPointModel(
        name: 'Rumah Satria Perkasa',
        address: 'Jl. Senopati No. 42',
        city: 'Jakarta Selatan',
        latitude: -6.2341,
        longitude: 106.8093,
      ),
      courierPosition: const LocationPointModel(
        name: 'Telah Diterima Satria (Penerima Langsung)',
        address: 'Jl. Senopati No. 42',
        city: 'Jakarta Selatan',
        latitude: -6.2341,
        longitude: 106.8093,
      ),
      etaMinutes: 0,
      distanceKm: 0.0,
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      timeline: const [],
    ),
    ShipmentModel(
      id: 'shp-004',
      trackingNumber: 'SS-31089-ID',
      itemName: 'Dokumen Perjanjian Kerja Sama',
      itemCategory: 'Dokumen Penting',
      serviceType: 'SATSET Instant',
      status: ShipmentStatus.pending,
      origin: const LocationPointModel(
        name: 'Kantor Notaris Suryo & Rekan',
        address: 'Jl. Wolter Monginsidi No. 12',
        city: 'Jakarta Selatan',
        latitude: -6.2390,
        longitude: 106.8150,
      ),
      destination: const LocationPointModel(
        name: 'Wisma Nusantara Lt. 8',
        address: 'Jl. M.H. Thamrin No. 59',
        city: 'Jakarta Pusat',
        latitude: -6.1920,
        longitude: 106.8240,
      ),
      courierPosition: const LocationPointModel(
        name: 'Menunggu Alokasi Kurir Terdekat',
        address: 'Kebayoran Baru',
        city: 'Jakarta Selatan',
        latitude: -6.2390,
        longitude: 106.8150,
      ),
      etaMinutes: 35,
      distanceKm: 5.8,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      timeline: const [],
    ),
  ];

  @override
  Stream<ShipmentModel> getLiveActiveShipmentStream() {
    _streamController?.close();
    _streamController = StreamController<ShipmentModel>.broadcast(
      onListen: _startLiveSimulation,
      onCancel: _stopLiveSimulation,
    );
    // Kirim state awal segera setelah di-listen
    return _streamController!.stream;
  }

  void _startLiveSimulation() {
    _streamController?.add(_currentActiveShipment);

    // Kirim snapshot real-time setiap 5 detik (simulasi WebSocket/Firestore stream)
    _realtimeSimulationTimer?.cancel();
    _realtimeSimulationTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_streamController == null || _streamController!.isClosed) {
        timer.cancel();
        return;
      }

      _simulationStep++;

      // Koordinat kurir bergerak secara dinamis mendekati tujuan
      // Origin: (-6.2238, 106.8285), Dest: (-6.2341, 106.8093)
      final stepFactor = (_simulationStep % 10) / 10.0;
      final newLat = -6.2238 + ((-6.2341 - -6.2238) * (0.5 + stepFactor * 0.45));
      final newLng = 106.8285 + ((106.8093 - 106.8285) * (0.5 + stepFactor * 0.45));

      final updatedEta = (14 - (_simulationStep % 12)).clamp(2, 20);
      final updatedDistance = (2.1 - ((_simulationStep % 10) * 0.18)).clamp(0.3, 3.5);

      final updatedCourier = _currentActiveShipment.courier?.copyWith(
        latitude: newLat,
        longitude: newLng,
      );

      _currentActiveShipment = _currentActiveShipment.copyWith(
        courier: updatedCourier,
        courierPosition: LocationPointModel(
          name: 'Posisi Kurir Real-Time',
          address: stepFactor > 0.8
              ? 'Tiba di depan gerbang tujuan'
              : 'Melintasi Jl. Gunawarman No. ${(12 + _simulationStep * 2)}',
          city: 'Jakarta Selatan',
          latitude: newLat,
          longitude: newLng,
        ),
        etaMinutes: updatedEta,
        distanceKm: double.parse(updatedDistance.toStringAsFixed(1)),
        updatedAt: DateTime.now(),
      ) as ShipmentModel;

      _streamController?.add(_currentActiveShipment);
    });
  }

  void _stopLiveSimulation() {
    _realtimeSimulationTimer?.cancel();
  }

  @override
  Future<ShipmentModel> getActiveShipment() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentActiveShipment;
  }

  @override
  Future<List<ShipmentModel>> getRecentShipments() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _recentShipmentsMock;
  }

  @override
  Future<ShipmentModel?> trackShipment(String trackingNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = trackingNumber.trim().toUpperCase();

    if (_currentActiveShipment.trackingNumber == normalized) {
      return _currentActiveShipment;
    }

    for (final shipment in _recentShipmentsMock) {
      if (shipment.trackingNumber == normalized) {
        return shipment;
      }
    }

    // Jika nomor resi baru dicari (mock dynamic result)
    if (normalized.startsWith('SS-') || normalized.length >= 6) {
      return ShipmentModel(
        id: 'shp-mock-${DateTime.now().millisecondsSinceEpoch}',
        trackingNumber: normalized,
        itemName: 'Paket Pengiriman SatSet',
        itemCategory: 'General Cargo',
        serviceType: 'SATSET Express',
        status: ShipmentStatus.inTransit,
        origin: const LocationPointModel(
          name: 'Hub SatSet Jakarta Barat',
          address: 'Daan Mogot KM 11',
          city: 'Jakarta Barat',
          latitude: -6.1550,
          longitude: 106.7450,
        ),
        destination: const LocationPointModel(
          name: 'Penerima SatSet',
          address: 'Jl. Sudirman No. 88',
          city: 'Jakarta Selatan',
          latitude: -6.2190,
          longitude: 106.8220,
        ),
        courierPosition: const LocationPointModel(
          name: 'Sortir Hub Pusat',
          address: 'Sedang diberangkatkan ke Hub transit',
          city: 'Jakarta Pusat',
          latitude: -6.1800,
          longitude: 106.8100,
        ),
        etaMinutes: 45,
        distanceKm: 8.5,
        updatedAt: DateTime.now(),
        timeline: [
          ShipmentTimelineStepModel(
            title: 'Resi Dibuat',
            description: 'Nomor resi $normalized berhasil terdaftar',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isCompleted: true,
          ),
          ShipmentTimelineStepModel(
            title: 'Dalam Perjalanan Antar Hub',
            description: 'Paket sedang transit menuju kota tujuan',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isCompleted: false,
            isCurrent: true,
          ),
        ],
      );
    }

    return null;
  }

  @override
  Future<UserProfileModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (currentUser != null) {
      return UserProfileModel(
        id: currentUser!.id,
        name: currentUser!.name,
        avatarUrl: currentUser!.photoUrl ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        currentCity: 'Jakarta Selatan',
        currentSubdistrict: 'Kebayoran Baru',
        currentLatitude: -6.2415,
        currentLongitude: 106.8000,
        hasUnreadCourierUpdates: true,
        unreadCount: 2,
      );
    }
    return const UserProfileModel(
      id: 'usr-101',
      name: 'Satria Perkasa',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      currentCity: 'Jakarta Selatan',
      currentSubdistrict: 'Kebayoran Baru',
      currentLatitude: -6.2415,
      currentLongitude: 106.8000,
      hasUnreadCourierUpdates: true,
      unreadCount: 2,
    );
  }

  @override
  Future<void> markNotificationsAsRead() async {
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
