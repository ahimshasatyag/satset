abstract class MainNavigationRepository {
  /// Mengambil index tab customer yang terakhir dipilih
  Future<int> getLastSelectedTab();

  /// Menyimpan index tab customer yang terakhir dipilih
  Future<void> saveLastSelectedTab(int index);

  /// Mengambil index tab kurir yang terakhir dipilih
  Future<int> getCourierLastSelectedTab();

  /// Menyimpan index tab kurir yang terakhir dipilih
  Future<void> saveCourierLastSelectedTab(int index);

  /// Memverifikasi otorisasi akun kurir (employee_type = COURIER pada m_employee)
  Future<bool> verifyCourierAccess({
    required String userId,
    String? email,
  });

  /// Mengambil jumlah tugas aktif kurir
  Future<int> getActiveTasksCount(String courierId);

  /// Mengambil jumlah notifikasi belum dibaca
  Future<int> getUnreadNotificationsCount(String userId);

  /// Aliran data realtime pembaruan jumlah tugas aktif kurir
  Stream<int> streamActiveTasksCount(String courierId);

  /// Aliran data realtime notifikasi belum dibaca
  Stream<int> streamUnreadNotificationsCount(String userId);

  /// Mengakhiri sesi login kurir di Supabase
  Future<void> logout();
}
