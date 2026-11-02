import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/admin/auth/data/models/admin_user_model.dart';
import 'package:satset/features/admin/auth/domain/entities/admin_user.dart';
import 'package:satset/features/admin/auth/domain/repositories/admin_auth_repository.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_login_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_logout_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_bloc.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_event.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_state.dart';

class MockAdminAuthRepository implements AdminAuthRepository {
  AdminUser? loggedInAdmin;
  String? savedEmail;
  bool isRemember = false;

  @override
  Future<AdminUser> login({required String email, required String password}) async {
    if (email == 'admin@satset.id' && password == 'admin123') {
      final user = AdminUser(
        id: 'admin-1',
        name: 'Super Admin',
        email: email,
        phone: '081234567890',
        role: 'admin',
        idUsersRole: 1,
        employeeCode: 'ADM-001',
      );
      loggedInAdmin = user;
      return user;
    }
    throw Exception('Kredensial salah');
  }

  @override
  Future<AdminUser?> getCurrentAdmin() async {
    return loggedInAdmin;
  }

  @override
  Future<void> logout() async {
    loggedInAdmin = null;
  }

  @override
  Future<void> saveRememberMe({required String email, required bool remember}) async {
    savedEmail = email;
    isRemember = remember;
  }

  @override
  Future<Map<String, dynamic>> getRememberMe() async {
    return {
      'email': savedEmail,
      'rememberMe': isRemember,
    };
  }
}

void main() {
  group('Admin Auth Unit Tests', () {
    late MockAdminAuthRepository repository;
    late AdminLoginUseCase loginUseCase;
    late GetCurrentAdminUseCase getCurrentAdminUseCase;
    late AdminLogoutUseCase logoutUseCase;

    setUp(() {
      repository = MockAdminAuthRepository();
      loginUseCase = AdminLoginUseCase(repository);
      getCurrentAdminUseCase = GetCurrentAdminUseCase(repository);
      logoutUseCase = AdminLogoutUseCase(repository);
    });

    test('AdminUserModel converts to and from JSON correctly', () {
      final json = {
        'id': 'ADM-99',
        'nama_lengkap': 'Budi Santoso',
        'email': 'budi.admin@satset.id',
        'no_hp': '081999888777',
        'id_users_role': 1,
        'employee_code': '009',
        'employee_type': 'ADMIN',
        'is_active': true,
      };

      final model = AdminUserModel.fromJson(json, token: 'token-test');
      expect(model.id, 'ADM-99');
      expect(model.name, 'Budi Santoso');
      expect(model.email, 'budi.admin@satset.id');
      expect(model.idUsersRole, 1);
      expect(model.token, 'token-test');

      final user = model.toUser();
      expect(user.isAdmin, isTrue);
      expect(user.name, 'Budi Santoso');

      final serialized = model.toJson();
      expect(serialized['nama_lengkap'], 'Budi Santoso');
      expect(serialized['id_users_role'], 1);
    });

    test('AdminAuthBloc handles login success', () async {
      final bloc = AdminAuthBloc(
        loginUseCase: loginUseCase,
        getCurrentAdminUseCase: getCurrentAdminUseCase,
        logoutUseCase: logoutUseCase,
        repository: repository,
      );

      final states = <AdminAuthState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AdminAuthLoginSubmitted(
        email: 'admin@satset.id',
        password: 'admin123',
        rememberMe: true,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<AdminAuthLoading>());
      expect(states[1], isA<AdminAuthSuccess>());
      final success = states[1] as AdminAuthSuccess;
      expect(success.adminUser.email, 'admin@satset.id');

      await sub.cancel();
      await bloc.close();
    });

    test('AdminAuthBloc handles login failure', () async {
      final bloc = AdminAuthBloc(
        loginUseCase: loginUseCase,
        getCurrentAdminUseCase: getCurrentAdminUseCase,
        logoutUseCase: logoutUseCase,
        repository: repository,
      );

      final states = <AdminAuthState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AdminAuthLoginSubmitted(
        email: 'wrong@satset.id',
        password: 'invalid',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<AdminAuthLoading>());
      expect(states[1], isA<AdminAuthFailure>());
      final failure = states[1] as AdminAuthFailure;
      expect(failure.errorMessage, contains('Kredensial salah'));

      await sub.cancel();
      await bloc.close();
    });

    test('AdminAuthBloc handles logout and check session', () async {
      final bloc = AdminAuthBloc(
        loginUseCase: loginUseCase,
        getCurrentAdminUseCase: getCurrentAdminUseCase,
        logoutUseCase: logoutUseCase,
        repository: repository,
      );

      // 1. Simulasikan login
      await repository.login(email: 'admin@satset.id', password: 'admin123');

      final states = <AdminAuthState>[];
      final sub = bloc.stream.listen(states.add);

      // 2. Check session
      bloc.add(const AdminAuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(states.last, isA<AdminAuthSuccess>());

      // 3. Logout
      bloc.add(const AdminAuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(states.last, isA<AdminAuthUnauthenticated>());

      await sub.cancel();
      await bloc.close();
    });
  });
}

