import '../../domain/repositories/main_navigation_repository.dart';
import '../datasources/main_navigation_local_datasource.dart';
import '../datasources/main_navigation_remote_datasource.dart';

class MainNavigationRepositoryImpl implements MainNavigationRepository {
  final MainNavigationLocalDataSource localDataSource;
  final MainNavigationRemoteDataSource remoteDataSource;

  MainNavigationRepositoryImpl({
    MainNavigationLocalDataSource? localDataSource,
    MainNavigationRemoteDataSource? remoteDataSource,
  })  : localDataSource =
            localDataSource ?? MainNavigationLocalDataSourceImpl(),
        remoteDataSource =
            remoteDataSource ?? MainNavigationRemoteDataSourceImpl();

  @override
  Future<int> getLastSelectedTab() {
    return localDataSource.getLastSelectedTab();
  }

  @override
  Future<void> saveLastSelectedTab(int index) {
    return localDataSource.saveLastSelectedTab(index);
  }

  @override
  Future<int> getCourierLastSelectedTab() {
    return localDataSource.getCourierLastSelectedTab();
  }

  @override
  Future<void> saveCourierLastSelectedTab(int index) {
    return localDataSource.saveCourierLastSelectedTab(index);
  }

  @override
  Future<bool> verifyCourierAccess({
    required String userId,
    String? email,
  }) async {
    // 1. Cek dari remote data source (tabel m_employee di Supabase)
    final isAuthorized = await remoteDataSource.verifyCourierAccess(
      userId: userId,
      email: email,
    );

    // 2. Simpan hasil verifikasi ke cache lokal
    await localDataSource.cacheCourierAuthorization(userId, isAuthorized);
    return isAuthorized;
  }

  @override
  Future<int> getActiveTasksCount(String courierId) {
    return remoteDataSource.getActiveTasksCount(courierId);
  }

  @override
  Future<int> getUnreadNotificationsCount(String userId) {
    return remoteDataSource.getUnreadNotificationsCount(userId);
  }

  @override
  Stream<int> streamActiveTasksCount(String courierId) {
    return remoteDataSource.streamActiveTasksCount(courierId);
  }

  @override
  Stream<int> streamUnreadNotificationsCount(String userId) {
    return remoteDataSource.streamUnreadNotificationsCount(userId);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCourierSession();
  }
}
