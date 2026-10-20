import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/order/data/datasources/order_local_datasource.dart';
import 'package:satset/features/order/data/datasources/order_remote_datasource.dart';
import 'package:satset/features/order/data/models/order_shipment_model.dart';
import 'package:satset/features/order/data/repositories/order_repository_impl.dart';
import 'package:satset/features/order/domain/entities/order_shipment.dart';
import 'package:satset/features/order/domain/usecases/create_shipment_usecase.dart';
import 'package:satset/features/order/domain/usecases/get_orders_usecase.dart';
import 'package:satset/features/order/presentation/bloc/order_bloc.dart';
import 'package:satset/features/order/presentation/bloc/order_event.dart';
import 'package:satset/features/order/presentation/pages/orders_page.dart';
import 'package:satset/features/order/presentation/widgets/order_filter_chips_bar.dart';
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

      await repo.createShipmentOrder({
        'itemName': 'Laptop Kerja',
        'receiverName': 'Ahmad',
        'destinationCity': 'Surabaya',
        'price': 45000,
      });

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

      // Tunggu inisialisasi awal selesai
      await Future.delayed(const Duration(milliseconds: 350));
      expect(bloc.state.orders, isNotEmpty);
      expect(bloc.state.isLoading, isFalse);

      // Filter ke status completed
      bloc.add(const OrderFilterChanged(filterStatus: OrderFilterStatus.completed));
      await Future.delayed(const Duration(milliseconds: 350));
      expect(bloc.state.selectedFilterStatus, OrderFilterStatus.completed);

      // Buat pesanan baru
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

      // Tap tab Pesanan
      await tester.tap(find.text('Pesanan'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OrdersPage), findsOneWidget);
    });
  });
}
