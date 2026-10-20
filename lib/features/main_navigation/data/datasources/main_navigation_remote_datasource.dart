abstract class MainNavigationRemoteDataSource {
  Future<Map<String, dynamic>> getNavigationConfig();
}

class MainNavigationRemoteDataSourceImpl
    implements MainNavigationRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getNavigationConfig() async {
    return {
      'enable_instant_delivery': true,
      'server_status': 'online',
    };
  }
}
