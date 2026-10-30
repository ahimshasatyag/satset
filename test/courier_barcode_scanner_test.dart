import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/courier/barcode_scanner/data/datasources/courier_barcode_scanner_local_datasource.dart';
import 'package:satset/features/courier/barcode_scanner/data/datasources/courier_barcode_scanner_remote_datasource.dart';
import 'package:satset/features/courier/barcode_scanner/data/models/scanned_shipment_model.dart';
import 'package:satset/features/courier/barcode_scanner/data/repositories/courier_barcode_scanner_repository_impl.dart';
import 'package:satset/features/courier/barcode_scanner/domain/entities/barcode_scan_result.dart';
import 'package:satset/features/courier/barcode_scanner/domain/entities/scanned_shipment.dart';
import 'package:satset/features/courier/barcode_scanner/domain/usecases/get_recent_scans_usecase.dart';
import 'package:satset/features/courier/barcode_scanner/domain/usecases/process_scanned_shipment_usecase.dart';
import 'package:satset/features/courier/barcode_scanner/domain/usecases/scan_barcode_usecase.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/bloc/courier_barcode_scanner_bloc.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/bloc/courier_barcode_scanner_event.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/bloc/courier_barcode_scanner_state.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/pages/courier_barcode_scanner_page.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/widgets/barcode_scanner_viewfinder.dart';
import 'package:satset/features/courier/barcode_scanner/presentation/widgets/scanned_package_detail_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Courier Barcode Scanner Data Model & Domain Entities Tests', () {
    test('ScannedShipmentModel accurately parses database join and determines pickup context', () {
      final now = DateTime.now().toIso8601String();
      final dbMap = {
        'id': 'SHIP-123',
        'nomor_resi': 'SST-20261023-001',
        'barcode_value': 'SST-20261023-001',
        'status_id': 3,
        'pengirim_nama': 'Toko ABC',
        'pengirim_no_hp': '0811111111',
        'pengirim_alamat': 'Jl. Sumber Makmur No. 10',
        'pengirim_kota': 'Jakarta Selatan',
        'penerima_nama': 'Budi Santoso',
        'penerima_no_hp': '0822222222',
        'penerima_alamat': 'Jl. Mawar No. 5',
        'penerima_kota': 'Tangerang',
        'total_berat_gram': 2500,
        'catatan_pengiriman': 'Pecah belah',
        'created_at': now,
        'updated_at': now,
        'm_shipment_statuses': {
          'id': 3,
          'kode': 'PICKUP_SCHEDULED',
          'nama_status': 'Dijadwalkan Pickup',
        },
        'm_service_types': {'id': 2, 'kode': 'EXP', 'nama_layanan': 'Express'},
        't_shipment_payments': {'status_pembayaran': 'PAID'},
        't_shipment_assignments': {'id': 'ASN-1', 'courier_id': '6'},
      };

      final shipment = ScannedShipmentModel.fromDatabase(
        dbMap,
        activeCourierId: '6',
      );

      expect(shipment.shipmentId, 'SHIP-123');
      expect(shipment.trackingNumber, 'SST-20261023-001');
      expect(shipment.barcodeValue, 'SST-20261023-001');
      expect(shipment.processType, BarcodeScanProcessType.pickup);
      expect(shipment.contextPersonName, 'Toko ABC');
      expect(shipment.contextPersonRoleLabel, 'Pengirim');
      expect(shipment.isAssignedToActiveCourier, true);
      expect(shipment.isStatusPermittedForAction, true);
      expect(shipment.recommendedActionStatusCode, 'PICKED_UP');
      expect(shipment.recommendedActionLabel, 'Konfirmasi Pickup Paket');
      expect(shipment.formattedWeight, '2.5 kg');
    });

    test(
      'ScannedShipment accurately determines delivery context and next action',
      () {
        final now = DateTime.now().toIso8601String();
        final dbMap = {
          'id': 'SHIP-456',
          'nomor_resi': 'SST-20261023-002',
          'barcode_value': 'SST-20261023-002',
          'status_id': 7,
          'pengirim_nama': 'Toko ABC',
          'pengirim_no_hp': '0811111111',
          'penerima_nama': 'Budi Santoso',
          'penerima_no_hp': '0822222222',
          'penerima_alamat': 'Jl. Melati No. 8',
          'penerima_kota': 'Bandung',
          'total_berat_gram': 1000,
          'created_at': now,
          'updated_at': now,
          'm_shipment_statuses': {
            'id': 7,
            'kode': 'OUT_FOR_DELIVERY',
            'nama_status': 'Sedang Diantar ke Penerima',
          },
          't_shipment_payments': {'status_pembayaran': 'PAID'},
          't_shipment_assignments': {'id': 'ASN-2', 'courier_id': '10'},
        };

        // Cek jika login sebagai kurir '10' (tanggung jawabnya)
        final shipmentForCourier10 = ScannedShipmentModel.fromDatabase(
          dbMap,
          activeCourierId: '10',
        );
        expect(
          shipmentForCourier10.processType,
          BarcodeScanProcessType.outForDelivery,
        );
        expect(shipmentForCourier10.contextPersonName, 'Budi Santoso');
        expect(shipmentForCourier10.contextPersonRoleLabel, 'Penerima');
        expect(shipmentForCourier10.isAssignedToActiveCourier, true);
        expect(shipmentForCourier10.recommendedActionStatusCode, 'DELIVERED');

        // Cek jika kurir lain yang login ('99') -> bukan tanggung jawabnya
        final shipmentForCourier99 = ScannedShipmentModel.fromDatabase(
          dbMap,
          activeCourierId: '99',
        );
        expect(shipmentForCourier99.isAssignedToActiveCourier, false);
      },
    );
  });

  group('Courier Barcode Scanner Repository Tests', () {
    test('Rejects duplicate scan within the same session', () async {
      final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
      final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl();
      final repository = CourierBarcodeScannerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      // Simulasikan barcode sudah dipindai sesi ini
      localDataSource.addScannedBarcode('SST-DUPLICATE-001');

      final result = await repository.scanBarcode(
        barcodeValue: 'SST-DUPLICATE-001',
        courierId: '6',
        force: false,
      );

      expect(result.status, BarcodeScanStatus.duplicate);
      expect(
        result.message.contains('telah berhasil dipindai sebelumnya'),
        true,
      );
    });

    test('Allows force scan of duplicate barcode when requested', () async {
      final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
      final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl();
      final repository = CourierBarcodeScannerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      localDataSource.addScannedBarcode('SST-FORCE-001');

      final result = await repository.scanBarcode(
        barcodeValue: 'SST-FORCE-001',
        courierId: '6',
        force: true,
      );

      // Pada offline/mock, jika di-force hasilnya sukses
      expect(result.status, BarcodeScanStatus.success);
      expect(result.shipment != null, true);
    });
  });

  group('Courier Barcode Scanner BLoC Tests', () {
    test('Emits expected states on initialization and barcode scan', () async {
      final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
      final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl();
      final repository = CourierBarcodeScannerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final bloc = CourierBarcodeScannerBloc(
        scanBarcodeUseCase: ScanBarcodeUseCase(repository),
        processScannedShipmentUseCase: ProcessScannedShipmentUseCase(
          repository,
        ),
        getRecentScansUseCase: GetRecentScansUseCase(repository),
        repository: repository,
      );

      bloc.add(const BarcodeScannerInitialized(courierId: '6'));
      await pumpEventQueue();

      expect(bloc.state.activeCourierId, '6');
      expect(bloc.state.isScanning, true);

      // Simulasikan pemindaian barcode
      bloc.add(const BarcodeScanned('SST-TEST-123'));
      await pumpEventQueue();

      expect(bloc.state.isProcessing, false);
      expect(bloc.state.isScanning, false);
      expect(bloc.state.scannedShipment != null, true);
      expect(bloc.state.scannedShipment!.barcodeValue, 'SST-TEST-123');

      // Konfirmasi tindakan operasional
      bloc.add(
        const ShipmentActionConfirmed(
          newStatusCode: 'PICKED_UP',
          notes: 'Paket diambil langsung dari pengirim',
        ),
      );
      await pumpEventQueue();

      expect(bloc.state.actionSuccess, true);
      expect(bloc.state.scannedShipment!.statusCode, 'PICKED_UP');

      // Reset untuk memindai paket berikutnya
      bloc.add(const ResetScannerForNextPackage());
      await pumpEventQueue();

      expect(bloc.state.isScanning, true);
      expect(bloc.state.scannedShipment, null);

      await bloc.close();
    });
  });

  group('Courier Barcode Scanner Widget Tests', () {
    testWidgets(
      'Renders CourierBarcodeScannerPage with viewfinder and controls',
      (tester) async {
        final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
        final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl();
        final repository = CourierBarcodeScannerRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        final bloc = CourierBarcodeScannerBloc(
          scanBarcodeUseCase: ScanBarcodeUseCase(repository),
          processScannedShipmentUseCase: ProcessScannedShipmentUseCase(
            repository,
          ),
          getRecentScansUseCase: GetRecentScansUseCase(repository),
          repository: repository,
        );

        await tester.pumpWidget(
          MaterialApp(home: CourierBarcodeScannerPage(customBloc: bloc)),
        );

        await tester.pump();

        // Periksa keberadaan elemen utama
        expect(find.text('Barcode Scanner Kurir'), findsOneWidget);
        expect(find.byType(BarcodeScannerViewfinder), findsOneWidget);
        expect(find.text('Input Manual'), findsOneWidget);
        expect(find.text('Jeda Kamera'), findsOneWidget);

        await bloc.close();
      },
    );

    testWidgets('Displays ScannedPackageDetailCard when shipment recognized', (
      tester,
    ) async {
      final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
      final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl();
      final repository = CourierBarcodeScannerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final bloc = CourierBarcodeScannerBloc(
        scanBarcodeUseCase: ScanBarcodeUseCase(repository),
        processScannedShipmentUseCase: ProcessScannedShipmentUseCase(
          repository,
        ),
        getRecentScansUseCase: GetRecentScansUseCase(repository),
        repository: repository,
      );

      await tester.pumpWidget(
        MaterialApp(home: CourierBarcodeScannerPage(customBloc: bloc)),
      );

      // Trigger barcode scanned
      bloc.add(const BarcodeScanned('SST-20261023-001'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ScannedPackageDetailCard), findsOneWidget);
      expect(find.text('SST-20261023-001'), findsOneWidget);
      expect(find.text('Konfirmasi Pickup Paket'), findsOneWidget);

      await bloc.close();
    });
  });
}
