abstract class MainNavigationRepository {
  Future<int> getLastSelectedTab();
  Future<void> saveLastSelectedTab(int index);
}
