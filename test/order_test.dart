import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/customer/order/data/datasources/order_local_datasource.dart';
import 'package:satset/features/customer/order/data/datasources/order_remote_datasource.dart';
import 'package:satset/features/customer/order/data/models/order_shipment_model.dart';
import 'package:satset/features/customer/order/data/repositories/order_repository_impl.dart';
import 'package:satset/features/customer/order/domain/entities/order_shipment.dart';
import 'package:satset/features/customer/order/domain/usecases/create_shipment_usecase.dart';
import 'package:satset/features/customer/order/domain/usecases/get_orders_usecase.dart';
import 'package:satset/features/customer/order/presentation/bloc/order_bloc.dart';
import 'package:satset/features/customer/order/presentation/bloc/order_event.dart';
import 'package:satset/features/customer/order/presentation/pages/orders_page.dart';
import 'package:satset/features/customer/order/presentation/pages/payment_page.dart';
import 'package:satset/features/customer/order/presentation/widgets/order_filter_chips_bar.dart';
import 'package:satset/features/customer/order/presentation/widgets/orders_skeleton.dart';
import 'package:satset/features/customer/order/presentation/widgets/payment_skeleton.dart';
import 'package:satset/features/main_navigation/domain/entities/navigation_item.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_bloc.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_event.dart';
import 'package:satset/features/main_navigation/presentation/pages/main_navigation_page.dart';
import 'package:satset/features/main_navigation/presentation/widgets/satset_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Order Clean Architecture Tests', () {
    test('OrderShipmentModel serialization and deserialization', () {
      final now = DateTime.now();
      final model = OrderShipmentModel(
        id: 'ord-01',
        trackingNumber: 'SS-TEST-1234',
        itemName: 'Buku Pemrograman',
        itemCategory: 'Buku',
        serviceType: 'SATSET Instant',
        direction: OrderDirection.outgoing,
        filterStatus: OrderFilterStatus.inDelivery,
        senderName: 'Satria',
        receiverName: 'Budi',
        originCity: 'Jakarta',
        destinationCity: 'Bandung',
        statusDescription: 'Sedang diantar',
        courierName: 'Doni',
        courierPhone: '08123456789',
        courierVehicle: 'B 1234 ABC',
        etaMinutes: 15,
        distanceKm: 2.5,
        price: 25000,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json['id'], 'ord-01');
      expect(json['trackingNumber'], 'SS-TEST-1234');
      expect(json['direction'], 'outgoing');

      final fromJson = OrderShipmentModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.trackingNumber, model.trackingNumber);
      expect(fromJson.direction, OrderDirection.outgoing);
      expect(fromJson.filterStatus, OrderFilterStatus.inDelivery);
      expect(fromJson.isActive, isTrue);
    });

    test('ShipmentPaymentModel and Region Models parse Supabase data correctly', () {
      final paymentMap = {
        'id': 10,
        'shipment_id': 101,
        'nomor_pembayaran': 'PAY-SST-20261021-001',
        'metode_pembayaran': 'TRANSFER',
        'jumlah_bayar': 35000.0,
        'status_pembayaran': 'PAID',
        'provider': 'BCA_VA',
        'provider_reference': '8801999912345678',
        'paid_at': '2026-10-21T10:30:00Z',
        'created_at': '2026-10-21T10:00:00Z',
        'updated_at': '2026-10-21T10:30:00Z',
      };

      final payment = ShipmentPaymentModel.fromDatabase(paymentMap);
      expect(payment.id, 10);
      expect(payment.shipmentId, 101);
      expect(payment.paymentNumber, 'PAY-SST-20261021-001');
      expect(payment.status, OrderPaymentStatus.paid);
      expect(payment.isPaid, isTrue);
      expect(payment.provider, 'BCA_VA');

      final provMap = {'kode_provinsi': '31', 'nama_provinsi': 'DKI Jakarta'};
      final prov = ProvinceModel.fromDatabase(provMap);
      expect(prov.code, '31');
      expect(prov.name, 'DKI Jakarta');

      final regMap = {
        'kode_kabkot': '31.74',
        'kode_provinsi': '31',
        'nama_kabkot': 'Kota Jakarta Selatan',
        'jenis': 'KOTA',
      };
      final reg = RegencyModel.fromDatabase(regMap);
      expect(reg.code, '31.74');
      expect(reg.type, 'KOTA');

      final distMap = {
        'kode_kecamatan': '31.74.01',
        'kode_kabkot': '31.74',
        'nama_kecamatan': 'Tebet',
      };
      final dist = DistrictModel.fromDatabase(distMap);
      expect(dist.name, 'Tebet');

      final villMap = {
        'kode_kelurahan': '31.74.01.1001',
        'kode_kecamatan': '31.74.01',
        'nama_kelurahan': 'Tebet Barat',
        'kodepos': '12810',
      };
      final vill = VillageModel.fromDatabase(villMap);
      expect(vill.postalCode, '12810');
    });

    test('OrderRepository getOrders, createShipmentOrder, and count stream', () async {
      final remoteDataSource = OrderRemoteDataSourceImpl();
      final localDataSource = OrderLocalDataSourceImpl();
      final repo = OrderRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final orders = await repo.getOrders(direction: OrderDirection.outgoing);
      expect(orders, isNotEmpty);

      final stream = repo.getActiveOrdersCountStream();
      final firstCount = await stream.first;
      expect(firstCount, greaterThanOrEqualTo(0));

      final created = await repo.createShipmentOrder({
        'itemName': 'Laptop Kerja',
        'receiverName': 'Ahmad',
        'destinationCity': 'Surabaya',
        'price': 45000,
        'metode_pembayaran': 'TRANSFER',
      });
      expect(created.itemName, 'Laptop Kerja');
      expect(created.payment, isNotNull);

      final refreshedOrders = await repo.getOrders(direction: OrderDirection.outgoing);
      expect(refreshedOrders.any((o) => o.itemName == 'Laptop Kerja'), isTrue);
    });

    test('OrderBloc handles initial load, filtering, and order creation', () async {
      final remoteDataSource = OrderRemoteDataSourceImpl();
      final localDataSource = OrderLocalDataSourceImpl();
      final repo = OrderRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final bloc = OrderBloc(
        getOrdersUseCase: GetOrdersUseCase(repo),
        createShipmentUseCase: CreateShipmentUseCase(repo),
      );

      await Future.delayed(const Duration(milliseconds: 350));
      expect(bloc.state.orders, isNotEmpty);
      expect(bloc.state.isLoading, isFalse);

      bloc.add(const OrderFilterChanged(filterStatus: OrderFilterStatus.completed));
      await Future.delayed(const Duration(milliseconds: 350));
      expect(bloc.state.selectedFilterStatus, OrderFilterStatus.completed);

      bloc.add(const OrderCreateSubmitted({
        'itemName': 'Paket Uji Bloc',
        'receiverName': 'Tester',
        'destinationCity': 'Jakarta',
      }));
      await Future.delayed(const Duration(milliseconds: 500));
      expect(bloc.state.message, isNotNull);

      await bloc.close();
    });

    test('NavigationBloc manages tabs and listens to active count stream', () async {
      final navBloc = NavigationBloc();

      expect(navBloc.state.currentTab, NavigationTab.home);

      navBloc.add(const NavigationTabChanged(NavigationTab.orders));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(navBloc.state.currentTab, NavigationTab.orders);

      await navBloc.close();
    });

    testWidgets('OrdersPage widget renders tab bar and filter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrdersPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Kiriman Saya'), findsOneWidget);
      expect(find.text('Paket Masuk'), findsOneWidget);
      expect(find.byType(OrderFilterChipsBar), findsOneWidget);
    });

    testWidgets('PaymentPage renders order details, VA number and instructions',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final testOrder = OrderShipment(
        id: 'ord-pay-01',
        trackingNumber: 'SST-20261021-999',
        barcodeValue: 'SST-20261021-999',
        itemName: 'Kamera Mirrorless',
        itemCategory: 'Elektronik',
        serviceType: 'Express',
        direction: OrderDirection.outgoing,
        filterStatus: OrderFilterStatus.waitingPickup,
        senderName: 'Pengirim SatSet',
        receiverName: 'Penerima SatSet',
        originCity: 'Jakarta Selatan',
        destinationCity: 'Bandung',
        statusDescription: 'Menunggu Pembayaran',
        courierName: 'Kurir SatSet',
        courierPhone: '-',
        courierVehicle: 'SatSet Fleet',
        etaMinutes: 30,
        distanceKm: 5.0,
        price: 35000,
        totalPrice: 35000,
        paymentMethod: 'TRANSFER',
        payment: ShipmentPayment(
          id: 1,
          shipmentId: 1,
          paymentNumber: 'PAY-SST-999',
          paymentMethod: 'TRANSFER',
          amount: 35000,
          status: OrderPaymentStatus.pending,
          provider: 'BCA_VA',
          providerReference: '8801999988887777',
          createdAt: now,
          updatedAt: now,
          expiredAt: now.add(const Duration(hours: 24)),
        ),
        createdAt: now,
        updatedAt: now,
      );

      final repo = OrderRepositoryImpl(
        remoteDataSource: OrderRemoteDataSourceImpl(),
        localDataSource: OrderLocalDataSourceImpl(),
      );

      final bloc = OrderBloc(
        getOrdersUseCase: GetOrdersUseCase(repo),
        createShipmentUseCase: CreateShipmentUseCase(repo),
        repository: repo,
      );

      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OrderBloc>.value(
            value: bloc,
            child: PaymentPage(
              order: testOrder,
              enableCountdown: false,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pembayaran Pesanan'), findsOneWidget);
      expect(find.text('SST-20261021-999'), findsNWidgets(2));
      expect(find.text('8801999988887777'), findsOneWidget);
      expect(find.text('Kamera Mirrorless'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('MainNavigationPage renders bottom nav bar with orders tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byType(SatSetBottomNavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Pesanan'), findsOneWidget);

      await tester.tap(find.text('Pesanan'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OrdersPage), findsOneWidget);
    });

    testWidgets('OrdersSkeleton renders card and header shimmer placeholders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrdersSkeleton(showHeader: true, itemCount: 3),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OrdersSkeleton), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'PaymentSkeleton and PaymentPage isLoading render shimmer correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentSkeleton(showAppBar: true),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PaymentSkeleton), findsOneWidget);

      final now = DateTime.now();
      final dummyOrder = OrderShipment(
        id: 'ord-skel-01',
        trackingNumber: 'SST-SKEL-123',
        barcodeValue: 'SST-SKEL-123',
        itemName: 'Kemeja Batik',
        itemCategory: 'Pakaian',
        serviceType: 'Regular',
        direction: OrderDirection.outgoing,
        filterStatus: OrderFilterStatus.waitingPickup,
        senderName: 'Pengirim',
        receiverName: 'Penerima',
        originCity: 'Jakarta',
        destinationCity: 'Surabaya',
        statusDescription: 'Menunggu',
        courierName: 'Kurir',
        courierPhone: '-',
        courierVehicle: 'Motor',
        etaMinutes: 20,
        distanceKm: 3.0,
        price: 20000,
        totalPrice: 20000,
        paymentMethod: 'TRANSFER',
        createdAt: now,
        updatedAt: now,
      );

      final repo = OrderRepositoryImpl(
        remoteDataSource: OrderRemoteDataSourceImpl(),
        localDataSource: OrderLocalDataSourceImpl(),
      );
      final bloc = OrderBloc(
        getOrdersUseCase: GetOrdersUseCase(repo),
        createShipmentUseCase: CreateShipmentUseCase(repo),
        repository: repo,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OrderBloc>.value(
            value: bloc,
            child: PaymentPage(
              order: dummyOrder,
              enableCountdown: false,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PaymentSkeleton), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
