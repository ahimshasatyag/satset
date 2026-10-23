import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:satset/features/auth/data/models/user_model.dart';
import 'package:satset/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:satset/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:satset/features/auth/domain/usecases/login_usecase.dart';
import 'package:satset/features/auth/domain/usecases/logout_usecase.dart';
import 'package:satset/features/auth/domain/usecases/register_usecase.dart';
import 'package:satset/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:satset/features/auth/presentation/bloc/auth_event.dart';
import 'package:satset/features/auth/presentation/bloc/auth_state.dart';
import 'package:satset/features/auth/presentation/pages/courier_register_page.dart';
import 'package:satset/features/auth/presentation/pages/login_page.dart';

void main() {
  group('Courier Register Feature & m_employee Persistence Tests', () {
    late AuthRemoteDataSource remoteDataSource;
    late AuthLocalDataSource localDataSource;
    late AuthRepositoryImpl repository;
    late AuthBloc authBloc;

    setUp(() {
      remoteDataSource = AuthRemoteDataSourceImpl();
      localDataSource = AuthLocalDataSourceImpl();
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      authBloc = AuthBloc(
        loginUseCase: LoginUseCase(repository),
        registerUseCase: RegisterUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        getCurrentUserUseCase: GetCurrentUserUseCase(repository),
        repository: repository,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('Database constants match table m_employee requirements', () {
      expect(DatabaseConstants.tableEmployee, equals('m_employee'));
      expect(EmployeeTableColumns.employeeCode, equals('employee_code'));
      expect(EmployeeTableColumns.namaLengkap, equals('nama_lengkap'));
      expect(EmployeeTableColumns.email, equals('email'));
      expect(EmployeeTableColumns.noHp, equals('no_hp'));
      expect(EmployeeTableColumns.password, equals('password'));
      expect(EmployeeTableColumns.idUsersRole, equals('id_users_role'));
    });

    test('AuthRemoteDataSource.registerCourier creates courier with id_users_role=2', () async {
      final courier = await remoteDataSource.registerCourier(
        name: 'Rian Kurniawan',
        email: 'rian.courier@satset.id',
        phone: '081234567890',
        password: 'Password123!',
        alamatLengkap: 'Jl. Merdeka No. 1, Jakarta',
      );

      expect(courier.name, equals('Rian Kurniawan'));
      expect(courier.email, equals('rian.courier@satset.id'));
      expect(courier.phone, equals('081234567890'));
      expect(courier.idUsersRole, equals(2));
      expect(courier.role, equals('courier'));
      expect(courier.isCourier, isTrue);
    });

    test('AuthBloc handles AuthCourierRegisterSubmitted and emits AuthSuccess', () async {
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);
      addTearDown(subscription.cancel);

      authBloc.add(const AuthCourierRegisterSubmitted(
        name: 'Doni Pratama',
        email: 'doni.courier@satset.id',
        phone: '089876543210',
        password: 'CourierSecure99!',
      ));

      await Future.delayed(const Duration(milliseconds: 700));

      expect(states.any((s) => s is AuthLoading), isTrue);
      final successState = states.whereType<AuthSuccess>().firstOrNull;
      expect(successState, isNotNull);
      expect(successState!.user.idUsersRole, equals(2));
      expect(successState.user.isCourier, isTrue);
    });

    testWidgets('CourierRegisterPage renders courier registration form fields and button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const CourierRegisterPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi judul dan elemen kurir
      expect(find.text('Daftar Akun Kurir'), findsOneWidget);
      expect(find.text('PENDAFTARAN MITRA KURIR'), findsOneWidget);

      // Verifikasi label form
      expect(find.text('Nama Lengkap Kurir'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Nomor Handphone (WhatsApp Aktif)'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);

      // Verifikasi tombol daftar kurir
      expect(find.text('Daftar sebagai Kurir'), findsOneWidget);
    });

    testWidgets('LoginPage includes link to CourierRegisterPage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const LoginPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi tautan pendaftaran kurir
      expect(find.text('Gabung Menjadi Mitra Kurir SatSet'), findsOneWidget);
    });
  });
}
