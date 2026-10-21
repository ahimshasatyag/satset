import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/shipments/data/datasources/shipment_local_datasource.dart';
import 'package:satset/features/shipments/data/datasources/shipment_remote_datasource.dart';
import 'package:satset/features/shipments/data/models/shipment_model.dart';
import 'package:satset/features/shipments/data/repositories/shipment_repository_impl.dart';
import 'package:satset/features/shipments/domain/usecases/create_shipment_usecase.dart';
import 'package:satset/features/shipments/presentation/bloc/shipment_bloc.dart';
import 'package:satset/features/shipments/presentation/bloc/shipment_event.dart';
import 'package:satset/features/shipments/presentation/pages/create_shipment_page.dart';
import 'package:satset/features/shipments/presentation/widgets/create_shipment_sheet.dart';
import 'package:satset/shared/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Shipments Feature Clean Architecture Tests', () {
    test('ShipmentModel and regional models parse database correctly', () {
      const provModel = ProvinceModel(code: '31', name: 'DKI JAKARTA');
      expect(provModel.code, '31');
      expect(provModel.name, 'DKI JAKARTA');

      final sModel = ServiceTypeModel.fromDatabase({
        'id': 2,
        'kode': 'EXP',
        'nama_layanan': 'Express Kilat',
        'estimasi_hari_min': 1,
        'estimasi_hari_max': 1,
        'deskripsi': 'Besok Sampai',
      });
      expect(sModel.code, 'EXP');
      expect(sModel.basePrice, 25000);
    });

    test('ShipmentRepository and CreateShipmentUseCase work in offline mock',
        () async {
      final remote = ShipmentRemoteDataSourceImpl();
      final local = ShipmentLocalDataSourceImpl();
      final repo = ShipmentRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final useCase = CreateShipmentUseCase(repo);

      final payload = {
        'pengirim_nama': 'Budi',
        'penerima_nama': 'Siti',
        'service_type_id': 2,
        'total_berat_gram': 2000,
        'panjang_cm': 20,
        'lebar_cm': 10,
        'tinggi_cm': 10,
        'metode_pembayaran': 'TRANSFER',
        'payment_channel': 'BCA_VA',
      };

      final shipment = await useCase(payload);
      expect(shipment.senderName, 'Budi');
      expect(shipment.receiverName, 'Siti');
      expect(shipment.trackingNumber.startsWith('SST-'), isTrue);
      expect(shipment.payment, isNotNull);
    });

    test('ShipmentBloc handles master data load and creation events', () async {
      final remote = ShipmentRemoteDataSourceImpl();
      final local = ShipmentLocalDataSourceImpl();
      final repo = ShipmentRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
      final useCase = CreateShipmentUseCase(repo);

      final bloc = ShipmentBloc(
        createShipmentUseCase: useCase,
        repository: repo,
      );
      addTearDown(bloc.close);

      bloc.add(const ShipmentInitMasterDataRequested());
      await Future.delayed(const Duration(milliseconds: 300));
      expect(bloc.state.provinces.isNotEmpty, isTrue);
      expect(bloc.state.serviceTypes.isNotEmpty, isTrue);

      bloc.add(const ShipmentCreateSubmitted({
        'pengirim_nama': 'Rian',
        'penerima_nama': 'Dewi',
      }));
      await Future.delayed(const Duration(milliseconds: 300));
      expect(bloc.state.createdShipment, isNotNull);
      expect(bloc.state.successMessage, isNotNull);

      bloc.add(const ShipmentCreatedReset());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.createdShipment, isNull);
    });

    testWidgets('CreateShipmentSheet and CreateShipmentPage render correctly',
        (WidgetTester tester) async {
      final remote = ShipmentRemoteDataSourceImpl();
      final local = ShipmentLocalDataSourceImpl();
      final repo = ShipmentRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateShipmentPage(
              repository: repo,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CreateShipmentSheet), findsOneWidget);
      expect(find.text('Buat Pengiriman Baru'), findsOneWidget);
    });

    testWidgets('CreateShipmentSkeleton renders shimmer placeholders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateShipmentSkeleton(
            showAppBar: true,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CreateShipmentSkeleton), findsOneWidget);
      expect(find.byType(CustomShimmer), findsWidgets);
    });

    testWidgets('SearchableDropdown renders matching image design and handles search filtering',
        (WidgetTester tester) async {
      String? selectedRole;
      final roles = ['Developer', 'Designer', 'Consultant', 'Student'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SearchableDropdown<String>(
                  label: 'Job Role',
                  hintText: 'Select job role',
                  searchHint: 'Search',
                  value: selectedRole,
                  items: roles,
                  itemLabel: (r) => r,
                  onChanged: (val) {
                    setState(() {
                      selectedRole = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // 1. Initial State: shows hint and down chevron
      expect(find.text('Select job role'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.text('Developer'), findsNothing);

      // 2. Tap to expand: shows up chevron and search field
      await tester.tap(find.text('Select job role'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('Consultant'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);

      // 3. Search filter: type 'des' -> Designer shows, Developer hidden
      await tester.enterText(find.byType(TextField), 'des');
      await tester.pumpAndSettle();

      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('Developer'), findsNothing);

      // 4. Select Designer: updates value and closes dropdown
      await tester.tap(find.text('Designer'));
      await tester.pumpAndSettle();

      expect(selectedRole, 'Designer');
      expect(find.text('Designer'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
