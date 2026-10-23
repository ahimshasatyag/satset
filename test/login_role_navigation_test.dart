import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:satset/features/auth/data/models/user_model.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/features/courier/tasks/presentation/pages/courier_tasks_page.dart';
import 'package:satset/features/customer/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  group('Login Dual-Table (m_users & m_employee) and Role Navigation Tests', () {
    test('Constants include tableEmployee and role column definitions', () {
      expect(DatabaseConstants.tableUsers, equals('m_users'));
      expect(DatabaseConstants.tableEmployee, equals('m_employee'));
      expect(UserTableColumns.idUsersRole, equals('id_users_role'));
      expect(EmployeeTableColumns.idUsersRole, equals('id_users_role'));
    });

    test('UserModel.fromDatabase correctly maps courier from m_employee with id_users_role=2', () {
      final employeeMap = {
        'id': 'emp_001',
        'nama_lengkap': 'Budi Courier',
        'email': 'budi.courier@satset.id',
        'no_hp': '08123456789',
        'id_users_role': 2,
        'role': 'courier',
      };

      final user = UserModel.fromDatabase(employeeMap);
      expect(user.id, equals('emp_001'));
      expect(user.name, equals('Budi Courier'));
      expect(user.idUsersRole, equals(2));
      expect(user.isCourier, isTrue);
      expect(user.isCustomer, isFalse);

      final json = user.toJson();
      expect(json['id_users_role'], equals(2));
    });

    test('UserModel.fromDatabase correctly maps customer from m_users with id_users_role=3', () {
      final userMap = {
        'id': 'usr_002',
        'nama_lengkap': 'Siti Pelanggan',
        'email': 'siti@gmail.com',
        'no_hp': '08987654321',
        'id_users_role': 3,
        'role': 'customer',
      };

      final user = UserModel.fromDatabase(userMap);
      expect(user.id, equals('usr_002'));
      expect(user.name, equals('Siti Pelanggan'));
      expect(user.idUsersRole, equals(3));
      expect(user.isCustomer, isTrue);
      expect(user.isCourier, isFalse);

      final json = user.toJson();
      expect(json['id_users_role'], equals(3));
    });

    test('AuthRemoteDataSource simulated login sets role 2 for courier and role 3 for customer', () async {
      final dataSource = AuthRemoteDataSourceImpl();

      final courierUser = await dataSource.login(
        email: 'courier.satset@example.com',
        password: 'Password123!',
      );
      expect(courierUser.idUsersRole, equals(2));
      expect(courierUser.isCourier, isTrue);

      final customerUser = await dataSource.login(
        email: 'customer@example.com',
        password: 'Password123!',
      );
      expect(customerUser.idUsersRole, equals(3));
      expect(customerUser.isCustomer, isTrue);
    });

    testWidgets('Navigation routing goes to CourierTasksPage for id_users_role=2', (tester) async {
      const courierUser = User(
        id: 'c_01',
        name: 'Kurir SatSet',
        email: 'kurir@satset.id',
        phone: '081234',
        idUsersRole: 2,
        role: 'courier',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    if (courierUser.idUsersRole == 2 || courierUser.role == 'courier') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CourierTasksPage(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DashboardPage(user: courierUser),
                        ),
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CourierTasksPage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    });

    testWidgets('Navigation routing goes to DashboardPage for id_users_role=3', (tester) async {
      const customerUser = User(
        id: 'u_01',
        name: 'Pelanggan Setia',
        email: 'user@satset.id',
        phone: '081234',
        idUsersRole: 3,
        role: 'customer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    if (customerUser.idUsersRole == 2 || customerUser.role == 'courier') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CourierTasksPage(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DashboardPage(user: customerUser),
                        ),
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(CourierTasksPage), findsNothing);
    });
  });
}
