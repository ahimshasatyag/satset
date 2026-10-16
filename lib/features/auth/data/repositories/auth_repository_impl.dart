import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementasi [AuthRepository] yang menjembatani data source lokal & remote ke domain
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final userModel = await remoteDataSource.login(
      email: email,
      password: password,
    );

    // Simpan data sesi & preferensi remember me
    await localDataSource.saveUser(userModel);
    await localDataSource.saveRememberMe(rememberMe);

    if (rememberMe) {
      await localDataSource.saveSavedEmail(email);
    } else {
      await localDataSource.saveSavedEmail('');
    }

    return userModel;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final userModel = await remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    await localDataSource.saveUser(userModel);
    return userModel;
  }

  @override
  Future<User> loginWithGoogle() async {
    final userModel = await remoteDataSource.loginWithGoogle();
    await localDataSource.saveUser(userModel);
    await localDataSource.saveRememberMe(true);
    return userModel;
  }

  @override
  Future<User?> getCurrentUser() async {
    return await localDataSource.getUser();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.deleteUser();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await remoteDataSource.forgotPassword(email);
  }

  @override
  Future<bool> isRememberMe() async {
    return await localDataSource.isRememberMe();
  }
}
