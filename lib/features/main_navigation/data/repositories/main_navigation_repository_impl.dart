import '../../domain/repositories/main_navigation_repository.dart';
import '../datasources/main_navigation_local_datasource.dart';

class MainNavigationRepositoryImpl implements MainNavigationRepository {
  final MainNavigationLocalDataSource localDataSource;

  MainNavigationRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<int> getLastSelectedTab() {
    return localDataSource.getLastSelectedTab();
  }

  @override
  Future<void> saveLastSelectedTab(int index) {
    return localDataSource.saveLastSelectedTab(index);
  }
}
