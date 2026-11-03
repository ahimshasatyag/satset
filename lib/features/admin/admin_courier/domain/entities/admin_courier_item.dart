/// Ringkasan statistik jumlah kurir untuk halaman Admin Courier Management
class AdminCourierSummaryStats {
  final int totalCouriers;
  final int activeCouriers;
  final int inactiveCouriers;
  final int couriersWithActiveTask;
  final int couriersWithoutActiveTask;

  const AdminCourierSummaryStats({
    required this.totalCouriers,
    required this.activeCouriers,
    required this.inactiveCouriers,
    required this.couriersWithActiveTask,
    required this.couriersWithoutActiveTask,
  });

  static const empty = AdminCourierSummaryStats(
    totalCouriers: 0,
    activeCouriers: 0,
    inactiveCouriers: 0,
    couriersWithActiveTask: 0,
    couriersWithoutActiveTask: 0,
  );
}

/// Lokasi GPS terakhir kurir dari t_shipment_locations
class AdminCourierLastLocation {
  final int id;
  final int shipmentId;
  final String? nomorResi;
  final int courierId;
  final double latitude;
  final double longitude;
  final double? speedMps;
  final double? heading;
  final double? accuracyM;
  final DateTime recordedAt;

  const AdminCourierLastLocation({
    required this.id,
    required this.shipmentId,
    this.nomorResi,
    required this.courierId,
    required this.latitude,
    required this.longitude,
    this.speedMps,
    this.heading,
    this.accuracyM,
    required this.recordedAt,
  });
}

/// Entitas Kurir pada daftar tabel utama (dari m_employee dengan id_users_role = 2)
class AdminCourierItem {
  final int id;
  final String employeeCode;
  final String? authUserId;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;
  final String? fotoUrl;
  final int idUsersRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Data agregasi aktual dari t_shipment_assignments & t_shipments
  final int activeTasksCount;
  final int totalHandledCount;
  final int deliveredCount;
  final int failedCount;
  final AdminCourierLastLocation? lastLocation;

  const AdminCourierItem({
    required this.id,
    required this.employeeCode,
    this.authUserId,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
    this.fotoUrl,
    this.idUsersRole = 2,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.activeTasksCount = 0,
    this.totalHandledCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.lastLocation,
  });

  bool get hasActiveAssignment => activeTasksCount > 0;

  String get activityStatusLabel {
    if (!isActive) return 'Akun Nonaktif';
    if (activeTasksCount > 0) return 'Bertugas ($activeTasksCount Paket)';
    return 'Siap Ditugaskan (Standby)';
  }
}

/// Hasil paginasi daftar kurir beserta ringkasan statistik aktual
class AdminCouriersPaginatedResult {
  final List<AdminCourierItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final AdminCourierSummaryStats summaryStats;

  const AdminCouriersPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.summaryStats,
  });

  int get totalPages =>
      totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  static const empty = AdminCouriersPaginatedResult(
    items: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 10,
    summaryStats: AdminCourierSummaryStats.empty,
  );
}

