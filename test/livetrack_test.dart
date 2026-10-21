import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/customer/livetrack/data/datasources/live_track_local_datasource.dart';
import 'package:satset/features/customer/livetrack/data/models/live_track_shipment_model.dart';
import 'package:satset/features/customer/livetrack/domain/entities/live_track_shipment.dart';
import 'package:satset/features/customer/livetrack/domain/usecases/get_live_tracking_orders_stream_usecase.dart';
import 'package:satset/features/customer/livetrack/presentation/bloc/live_track_bloc.dart';
import 'package:satset/features/customer/livetrack/presentation/bloc/live_track_event.dart';
import 'package:satset/features/customer/livetrack/presentation/bloc/live_track_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveTrack Clean Architecture Unit Tests', () {
    late LiveTrackLocalDataSource localDataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localDataSource = LiveTrackLocalDataSourceImpl();
    });

    test('LiveTrackShipmentModel.fromDatabase maps Supabase relations correctly', () {
      final dbMap = {
        'id': 101,
        'nomor_resi': 'SS-REAL-9912',
        'barcode_value': 'SS-REAL-9912',
        'customer_id': 5,
        'service_type_id': 1,
        'm_service_types': {
          'id': 1,
          'kode': 'INSTANT',
          'nama_layanan': 'SATSET Instant',
        },
        'status_id': 7,
        'm_shipment_statuses': {
          'id': 7,
          'kode': 'OUT_FOR_DELIVERY',
          'nama_status': 'Sedang Diantar Kurir',
        },
        'pengirim_nama': 'Toko Buku Maju',
        'pengirim_no_hp': '0811112222',
        'pengirim_alamat': 'Jl. Kemang Raya No. 10',
        'pengirim_kota': 'Jakarta Selatan',
        'penerima_nama': 'Budi Santoso',
        'penerima_no_hp': '081234567890',
        'penerima_alamat': 'Jl. Kebayoran Baru No. 25',
        'penerima_kota': 'Jakarta Selatan',
        'penerima_latitude': -6.2440,
        'penerima_longitude': 106.7950,
        'total_biaya': 25000,
        'total_berat_gram': 500,
        'catatan_pengiriman': 'Tolong titip di satpam jika tidak ada orang',
        't_shipment_tracking': [
          {
            'id': 1,
            'shipment_id': 101,
            'status_id': 4,
            'm_shipment_statuses': {
              'id': 4,
              'kode': 'PICKED_UP',
              'nama_status': 'Telah Dijemput',
            },
            'lokasi_nama': 'Hub Kemang',
            'catatan': 'Paket telah dijemput dari pengirim',
            'created_at': '2026-10-21T08:00:00Z',
          },
          {
            'id': 2,
            'shipment_id': 101,
            'status_id': 7,
            'm_shipment_statuses': {
              'id': 7,
              'kode': 'OUT_FOR_DELIVERY',
              'nama_status': 'Sedang Diantar Kurir',
            },
            'lokasi_nama': 'Kebayoran Baru',
            'latitude': -6.2400,
            'longitude': 106.7990,
            'catatan': 'Kurir sedang menuju alamat penerima',
            'created_at': '2026-10-21T08:30:00Z',
          },
        ],
      };

      final latestLoc = {
        'id': 50,
        'shipment_id': 101,
        'latitude': -6.2410,
        'longitude': 106.7980,
        'heading': 180.0,
        'speed': 25.5,
        'created_at': DateTime.now().toIso8601String(),
      };

      final model = LiveTrackShipmentModel.fromDatabase(
        dbMap,
        currentCustomerId: 5,
        currentUserPhone: '081234567890',
        latestLocation: latestLoc,
      );

      expect(model.id, equals('101'));
      expect(model.trackingNumber, equals('SS-REAL-9912'));
      expect(model.serviceTypeName, equals('SATSET Instant'));
      expect(model.statusName, equals('Sedang Diantar Kurir'));
      expect(model.filterStatus, equals(OrderFilterStatus.inDelivery));
      expect(model.isCourierGpsAvailable, isTrue);
      expect(model.courierLatitude, equals(-6.2410));
      expect(model.courierLongitude, equals(106.7980));
      expect(model.hasDestinationCoordinates, isTrue);
      expect(model.distanceKm, isNotNull);
      expect(model.etaMinutes, isNotNull);
      expect(model.timeline.length, equals(2));
      expect(model.timeline.first.statusName, equals('Telah Dijemput'));
      expect(model.timeline.last.isCurrent, isTrue);
    });

    test('LiveTrackShipmentModel serialization works properly', () {
      final model = LiveTrackShipmentModel(
        id: 'test-1',
        trackingNumber: 'SS-TEST-01',
        barcodeValue: 'SS-TEST-01',
        customerId: 1,
        serviceTypeId: 1,
        serviceTypeName: 'SATSET Instant',
        serviceTypeCode: 'INSTANT',
        statusId: 7,
        statusCode: 'OUT_FOR_DELIVERY',
        statusName: 'Sedang Diantar Kurir',
        statusDescription: 'Kurir sedang membawa paket menuju alamat penerima',
        direction: OrderDirection.outgoing,
        filterStatus: OrderFilterStatus.inDelivery,
        senderName: 'Sender',
        senderPhone: '081111',
        senderAddress: 'Alamat Pengirim',
        senderCity: 'Jakarta',
        receiverName: 'Receiver',
        receiverPhone: '082222',
        receiverAddress: 'Alamat Penerima',
        receiverCity: 'Bandung',
        receiverLatitude: -6.2,
        receiverLongitude: 106.8,
        courierName: 'Budi',
        courierPhone: '081234',
        courierVehicle: 'Motor',
        courierLatitude: -6.205,
        courierLongitude: 106.805,
        courierLocationUpdatedAt: DateTime.now(),
        etaMinutes: 15,
        distanceKm: 3.0,
        totalPrice: 20000,
        totalWeightGram: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = model.toJson();
      expect(json['trackingNumber'], equals('SS-TEST-01'));
      expect(json['direction'], equals('outgoing'));
      expect(json['filterStatus'], equals('inDelivery'));

      final reconstructed = LiveTrackShipmentModel.fromJson(json);
      expect(reconstructed.id, equals(model.id));
      expect(reconstructed.trackingNumber, equals(model.trackingNumber));
      expect(reconstructed.direction, equals(OrderDirection.outgoing));
      expect(reconstructed.filterStatus, equals(OrderFilterStatus.inDelivery));
      expect(reconstructed.isCourierGpsAvailable, isTrue);
    });

    test('LiveTrackLocalDataSource saves and restores preferences', () async {
      await localDataSource.saveLastTrackedResi('SS-9999');
      final resi = await localDataSource.getLastTrackedResi();
      expect(resi, equals('SS-9999'));

      await localDataSource.saveMapZoom(16.5);
      final zoom = await localDataSource.getSavedMapZoom();
      expect(zoom, equals(16.5));

      await localDataSource.saveLastDirection(OrderDirection.incoming);
      final dir = await localDataSource.getLastDirection();
      expect(dir, equals(OrderDirection.incoming));
    });

    test('LiveTrackBloc state management and filtering', () async {
      final fakeStreamController =
          StreamController<List<LiveTrackShipment>>.broadcast();

      final fakeUseCase = _FakeGetStreamUseCase(fakeStreamController);

      final bloc = LiveTrackBloc(
        getLiveTrackingOrdersStreamUseCase: fakeUseCase,
      );

      // Verifikasi initial state
      expect(bloc.state.selectedDirection, equals(OrderDirection.outgoing));
      expect(bloc.state.selectedFilterStatus, equals(OrderFilterStatus.all));

      // Kirim daftar shipments via LiveTrackOrdersReceived
      final sampleShipments = [
        LiveTrackShipment(
          id: '1',
          trackingNumber: 'SS-001',
          barcodeValue: 'SS-001',
          customerId: 1,
          serviceTypeId: 1,
          serviceTypeName: 'SATSET Instant',
          serviceTypeCode: 'INSTANT',
          statusId: 7,
          statusCode: 'OUT_FOR_DELIVERY',
          statusName: 'Sedang Diantar Kurir',
          statusDescription: 'On the way',
          direction: OrderDirection.outgoing,
          filterStatus: OrderFilterStatus.inDelivery,
          senderName: 'Pengirim 1',
          senderPhone: '0811',
          senderAddress: 'Alamat 1',
          senderCity: 'Jakarta',
          receiverName: 'Penerima 1',
          receiverPhone: '0822',
          receiverAddress: 'Alamat 2',
          receiverCity: 'Jakarta',
          totalPrice: 15000,
          totalWeightGram: 500,
          createdAt: DateTime(2026, 10, 21),
          updatedAt: DateTime(2026, 10, 21),
        ),
        LiveTrackShipment(
          id: '2',
          trackingNumber: 'SS-002',
          barcodeValue: 'SS-002',
          customerId: 1,
          serviceTypeId: 2,
          serviceTypeName: 'SATSET Reguler',
          serviceTypeCode: 'REG',
          statusId: 8,
          statusCode: 'DELIVERED',
          statusName: 'Terkirim',
          statusDescription: 'Selesai',
          direction: OrderDirection.outgoing,
          filterStatus: OrderFilterStatus.completed,
          senderName: 'Pengirim 2',
          senderPhone: '0833',
          senderAddress: 'Alamat 3',
          senderCity: 'Bandung',
          receiverName: 'Penerima 2',
          receiverPhone: '0844',
          receiverAddress: 'Alamat 4',
          receiverCity: 'Bandung',
          totalPrice: 20000,
          totalWeightGram: 1000,
          createdAt: DateTime(2026, 10, 21),
          updatedAt: DateTime(2026, 10, 21),
        ),
      ];

      bloc.add(LiveTrackOrdersReceived(sampleShipments));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LiveTrackState>((s) =>
              s.allShipments.length == 2 && s.filteredShipments.length == 2 && !s.isLoading),
        ),
      );

      // Uji filter chip "Sedang Diantar"
      bloc.add(const LiveTrackFilterChanged(OrderFilterStatus.inDelivery));
      await expectLater(
        bloc.stream,
        emits(
          predicate<LiveTrackState>((s) =>
              s.selectedFilterStatus == OrderFilterStatus.inDelivery &&
              s.filteredShipments.length == 1 &&
              s.filteredShipments.first.trackingNumber == 'SS-001'),
        ),
      );

      // Uji pencarian resi
      bloc.add(const LiveTrackSearchQueryChanged('002'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<LiveTrackState>((s) =>
              s.searchQuery == '002' && s.filteredShipments.isEmpty),
        ),
      );

      // Kembalikan filter ke Semua
      bloc.add(const LiveTrackFilterChanged(OrderFilterStatus.all));
      await expectLater(
        bloc.stream,
        emits(
          predicate<LiveTrackState>((s) =>
              s.filteredShipments.length == 1 &&
              s.filteredShipments.first.trackingNumber == 'SS-002'),
        ),
      );

      // Uji zoom in & clamping
      bloc.add(const LiveTrackZoomChanged(20.0)); // melebihi batas 18.0
      await expectLater(
        bloc.stream,
        emits(predicate<LiveTrackState>((s) => s.zoomScale == 18.0)),
      );

      // Uji reset zoom center
      bloc.add(const LiveTrackResetCenter());
      await expectLater(
        bloc.stream,
        emits(predicate<LiveTrackState>((s) => s.zoomScale == 15.0)),
      );

      await bloc.close();
      await fakeStreamController.close();
    });
  });
}

class _FakeGetStreamUseCase extends Fake implements GetLiveTrackingOrdersStreamUseCase {
  final StreamController<List<LiveTrackShipment>> controller;

  _FakeGetStreamUseCase(this.controller);

  @override
  Stream<List<LiveTrackShipment>> call({
    required OrderDirection direction,
    String? specificResi,
  }) =>
      controller.stream;
}

