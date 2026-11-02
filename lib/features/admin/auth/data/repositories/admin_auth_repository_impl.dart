import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_auth_repository.dart';
import '../datasources/admin_auth_local_datasource.dart';
import '../datasources/admin_auth_remote_datasource.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminAuthRemoteDataSource remoteDataSource;
  final AdminAuthLocalDataSource localDataSource;

  AdminAuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AdminUser> login({
    required String email,
    required String password,
  }) async {
    final adminModel = await remoteDataSource.login(
      email: email,
      password: password,
    );
    await localDataSource.saveAdmin(adminModel);
    return adminModel;
  }

  @override
  Future<AdminUser?> getCurrentAdmin() async {
    return await localDataSource.getAdmin();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.deleteAdmin();
  }

  @override
  Future<void> saveRememberMe({required String email, required bool remember}) async {
    await localDataSource.saveRememberMe(email: email, remember: remember);
  }

  @override
  Future<Map<String, dynamic>> getRememberMe() async {
    return await localDataSource.getRememberMe();
  }
}

