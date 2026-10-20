import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/livetrack/data/datasources/live_track_local_datasource.dart';
import 'package:satset/features/livetrack/data/datasources/live_track_remote_datasource.dart';
import 'package:satset/features/livetrack/data/models/live_track_shipment_model.dart';
import 'package:satset/features/livetrack/data/repositories/live_track_repository_impl.dart';
import 'package:satset/features/livetrack/domain/entities/live_track_shipment.dart';
import 'package:satset/features/livetrack/domain/usecases/get_live_tracking_orders_stream_usecase.dart';
import 'package:satset/features/livetrack/presentation/bloc/live_track_bloc.dart';
import 'package:satset/features/livetrack/presentation/bloc/live_track_event.dart';
import 'package:satset/features/livetrack/presentation/bloc/live_track_state.dart';

void main() {
  group('LiveTrack Clean Architecture Unit Tests', () {
    late LiveTrackRemoteDataSource remoteDataSource;
    late LiveTrackLocalDataSource localDataSource;
    late LiveTrackRepositoryImpl repository;
    late GetLiveTrackingOrdersStreamUseCase getStreamUseCase;

    setUp(() {
      remoteDataSource = LiveTrackRemoteDataSourceImpl();
      localDataSource = LiveTrackLocalDataSourceImpl();
      repository = LiveTrackRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      getStreamUseCase = GetLiveTrackingOrdersStreamUseCase(repository);
    });

    test('LiveTrackRemoteDataSource emits live tracking stream items', () async {
      final stream = remoteDataSource.getLiveTrackingOrdersStream(
        direction: OrderDirection.outgoing,
      );

      final firstEvent = await stream.first;
      expect(firstEvent.isNotEmpty, isTrue);
      expect(firstEvent.first.direction, equals(OrderDirection.outgoing));
    });

    test('LiveTrackShipmentModel serialization works properly', () {
      final model = LiveTrackShipmentModel(
        id: 'test-1',
        trackingNumber: 'SS-TEST-01',
        itemName: 'Test Box',
        itemCategory: 'Dokumen',
        serviceType: 'SATSET Instant',
        direction: OrderDirection.outgoing,
        filterStatus: OrderFilterStatus.inDelivery,
        senderName: 'Sender',
        receiverName: 'Receiver',
        originCity: 'Jakarta',
        destinationCity: 'Bandung',
        statusDescription: 'On the way',
        courierName: 'Budi',
        courierPhone: '081234',
        courierVehicle: 'Motor',
        latitude: -6.2,
        longitude: 106.8,
        etaMinutes: 15,
        distanceKm: 3.0,
        price: 20000,
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
    });

    test('LiveTrackBloc state management and filtering', () async {
      final bloc = LiveTrackBloc(
        getLiveTrackingOrdersStreamUseCase: getStreamUseCase,
      );

      // Tunggu stream data pertama masuk
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LiveTrackState>((s) => s.allShipments.isNotEmpty && !s.isLoading),
        ),
      );

      expect(bloc.state.allShipments.isNotEmpty, isTrue);
      expect(bloc.state.selectedShipment, isNotNull);

      // Uji perubahan filter
      bloc.add(const LiveTrackFilterChanged(OrderFilterStatus.inDelivery));
      await expectLater(
        bloc.stream,
        emits(
          predicate<LiveTrackState>((s) =>
              s.selectedFilterStatus == OrderFilterStatus.inDelivery),
        ),
      );

      // Uji zoom in & clamping
      bloc.add(const LiveTrackZoomChanged(2.5)); // melebihi batas 1.8
      await expectLater(
        bloc.stream,
        emits(predicate<LiveTrackState>((s) => s.zoomScale == 1.8)),
      );

      // Uji reset zoom center
      bloc.add(const LiveTrackResetCenter());
      await expectLater(
        bloc.stream,
        emits(predicate<LiveTrackState>((s) => s.zoomScale == 1.0)),
      );

      await bloc.close();
    });
  });
}
