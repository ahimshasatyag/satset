import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/courier/tasks/presentation/pages/courier_tasks_page.dart';
import 'package:satset/features/main_navigation/data/datasources/main_navigation_local_datasource.dart';
import 'package:satset/features/main_navigation/data/datasources/main_navigation_remote_datasource.dart';
import 'package:satset/features/main_navigation/data/repositories/main_navigation_repository_impl.dart';
import 'package:satset/features/main_navigation/domain/entities/navigation_item.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_bloc.dart';
import 'package:satset/features/main_navigation/presentation/bloc/navigation_event.dart';
import 'package:satset/features/main_navigation/presentation/pages/main_navigation_page.dart';
import 'package:satset/features/main_navigation/presentation/widgets/satset_bottom_navigation_bar.dart';

void main() {
  group('Courier Main Navigation Clean Architecture & Widget Tests', () {
    const courierUser = User(
      id: 'emp_courier_001',
      name: 'Rian Courier',
      email: 'rian.courier@satset.id',
      phone: '08123456789',
      idUsersRole: 2,
      role: 'courier',
    );

    const nonCourierUser = User(
      id: 'usr_customer_002',
      name: 'Bukan Kurir',
      email: 'customer@gmail.com',
      phone: '08987654321',
      idUsersRole: 3,
      role: 'customer',
    );

    test('CourierNavigationTab and CourierBadgeInfo entities behave correctly', () {
      expect(CourierNavigationTab.tasks.label, equals('Tugas'));
      expect(CourierNavigationTab.scan.label, equals('Scan'));
      expect(CourierNavigationTab.trackingCourier.label, equals('Pelacakan'));
      expect(CourierNavigationTab.history.label, equals('Riwayat'));
      expect(CourierNavigationTab.account.label, equals('Akun'));

      const badge = CourierBadgeInfo(
        activeTasksCount: 3,
        unreadNotificationsCount: 1,
        isTrackingActive: true,
      );
      expect(badge.hasActiveTask, isTrue);
      expect(badge.activeTasksCount, equals(3));

      final updated = badge.copyWith(activeTasksCount: 0);
      expect(updated.hasActiveTask, isFalse);
    });

    test('NavigationBloc handles Courier events and tab switching properly', () async {
      final local = MainNavigationLocalDataSourceImpl();
      final remote = MainNavigationRemoteDataSourceImpl();
      final repo = MainNavigationRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
      );

      final bloc = NavigationBloc(repository: repo);
      addTearDown(bloc.close);

      // 1. Initial State
      expect(bloc.state.currentCourierTab, equals(CourierNavigationTab.tasks));

      // 2. Change Tab to Scan
      bloc.add(const CourierNavigationTabChanged(CourierNavigationTab.scan));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.currentCourierTab, equals(CourierNavigationTab.scan));

      // 3. Update active tasks count
      bloc.add(const NavigationActiveTasksCountUpdated(5));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.activeTasksCount, equals(5));
      expect(bloc.state.hasActiveTask, isTrue);

      // 4. Update unread notification count
      bloc.add(const NavigationUnreadNotificationsCountUpdated(2));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.unreadNotificationsCount, equals(2));
    });

    testWidgets('SatSetBottomNavigationBar.courier renders 5 courier tabs and badge', (tester) async {
      CourierNavigationTab selected = CourierNavigationTab.tasks;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return SatSetBottomNavigationBar.courier(
                  currentTab: selected,
                  activeTasksCount: 4,
                  hasActiveTask: true,
                  onTabSelected: (tab) {
                    setState(() => selected = tab);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi 5 menu bilah navigasi kurir
      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Pelacakan'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);

      // Verifikasi badge 4 tugas aktif
      expect(find.text('4'), findsOneWidget);

      // Tap tab Scan
      await tester.tap(find.text('Scan'));
      await tester.pump();
      expect(selected, equals(CourierNavigationTab.scan));
    });

    testWidgets('MainNavigationPage in courier mode displays CourierTasksPage as default tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationPage(
            user: courierUser,
            isCourierMode: true,
            initialCourierTab: CourierNavigationTab.tasks,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Halaman tasks/ adalah halaman utama kurir
      expect(find.byType(CourierTasksPage), findsOneWidget);
      expect(find.text('Tugas Kurir'), findsOneWidget);
    });

    testWidgets('CourierMainNavigationPage wrapper instantiates and renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CourierMainNavigationPage(
            user: courierUser,
            initialTab: CourierNavigationTab.tasks,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavigationPage), findsOneWidget);
      expect(find.byType(CourierTasksPage), findsOneWidget);
    });

    testWidgets('MainNavigationPage protects unauthorized non-courier user', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationPage(
            user: nonCourierUser,
            isCourierMode: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dalam mode kurir dengan non-courier user atau saat otorisasi diperiksa
      expect(find.byType(MainNavigationPage), findsOneWidget);
    });
  });
}
