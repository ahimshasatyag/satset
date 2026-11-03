/// Ringkasan statistik jumlah customer aktual dari tabel m_users (id_users_role = 3)
class AdminCustomerSummaryStats {
  final int totalCustomers;
  final int verifiedCustomers;
  final int unverifiedCustomers;
  final int newCustomersThisMonth;

  const AdminCustomerSummaryStats({
    required this.totalCustomers,
    required this.verifiedCustomers,
    required this.unverifiedCustomers,
    required this.newCustomersThisMonth,
  });

  static const empty = AdminCustomerSummaryStats(
    totalCustomers: 0,
    verifiedCustomers: 0,
    unverifiedCustomers: 0,
    newCustomersThisMonth: 0,
  );
}

/// Opsi wilayah berjenjang (m_provinsi, m_kabkot, m_kecamatan, m_kelurahan)
class AdminWilayahOption {
  final String kode;
  final String nama;
  final String? parentKode;
  final String? kodePos;

  const AdminWilayahOption({
    required this.kode,
    required this.nama,
    this.parentKode,
    this.kodePos,
  });
}

/// Entitas Customer pada daftar tabel utama (dari m_users dengan id_users_role = 3)
class AdminCustomerItem {
  final int id;
  final String namaLengkap;
  final String email;
  final String noHp;
  final int idUsersRole;
  final bool emailVerified;
  final DateTime? emailVerifiedAt;
  final String? googleId;
  final String? alamatLengkap;
  final String? idProvinsi;
  final String? namaProvinsi;
  final String? idKabkot;
  final String? namaKabkot;
  final String? idKecamatan;
  final String? namaKecamatan;
  final String? idKelurahan;
  final String? namaKelurahan;
  final String? kodePos;
  final double? latitude;
  final double? longitude;
  final bool isUtama;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Data agregasi aktual dari t_shipments & t_shipment_payments
  final int totalShipmentsCount;
  final int deliveredShipmentsCount;
  final int ongoingShipmentsCount;
  final int failedShipmentsCount;
  final num totalTransactionAmount;

  const AdminCustomerItem({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.idUsersRole = 3,
    required this.emailVerified,
    this.emailVerifiedAt,
    this.googleId,
    this.alamatLengkap,
    this.idProvinsi,
    this.namaProvinsi,
    this.idKabkot,
    this.namaKabkot,
    this.idKecamatan,
    this.namaKecamatan,
    this.idKelurahan,
    this.namaKelurahan,
    this.kodePos,
    this.latitude,
    this.longitude,
    this.isUtama = true,
    required this.createdAt,
    this.updatedAt,
    this.totalShipmentsCount = 0,
    this.deliveredShipmentsCount = 0,
    this.ongoingShipmentsCount = 0,
    this.failedShipmentsCount = 0,
    this.totalTransactionAmount = 0,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedWilayahSummary {
    final parts = <String>[
      if (namaKelurahan != null && namaKelurahan!.isNotEmpty) namaKelurahan!,
      if (namaKecamatan != null && namaKecamatan!.isNotEmpty) namaKecamatan!,
      if (namaKabkot != null && namaKabkot!.isNotEmpty) namaKabkot!,
      if (namaProvinsi != null && namaProvinsi!.isNotEmpty) namaProvinsi!,
      if (kodePos != null && kodePos!.isNotEmpty) kodePos!,
    ];
    if (parts.isEmpty) return alamatLengkap ?? '-';
    return parts.join(', ');
  }
}

/// Hasil paginasi daftar customer beserta ringkasan statistik aktual
class AdminCustomersPaginatedResult {
  final List<AdminCustomerItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final AdminCustomerSummaryStats summaryStats;

  const AdminCustomersPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.summaryStats,
  });

  int get totalPages =>
      totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  static const empty = AdminCustomersPaginatedResult(
    items: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 10,
    summaryStats: AdminCustomerSummaryStats.empty,
  );
}

