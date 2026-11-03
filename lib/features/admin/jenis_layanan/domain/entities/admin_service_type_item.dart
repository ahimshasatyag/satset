/// Statistik ringkasan aktual master jenis layanan (`m_service_types` & relasi `t_shipments`)
class AdminServiceTypeSummaryStats {
  final int totalServices;
  final int activeServices;
  final int inactiveServices;
  final int usedServicesCount;
  final int totalShipmentsUsingServices;
  final num totalRevenueFromServices;

  const AdminServiceTypeSummaryStats({
    required this.totalServices,
    required this.activeServices,
    required this.inactiveServices,
    required this.usedServicesCount,
    required this.totalShipmentsUsingServices,
    required this.totalRevenueFromServices,
  });

  static const AdminServiceTypeSummaryStats empty =
      AdminServiceTypeSummaryStats(
        totalServices: 0,
        activeServices: 0,
        inactiveServices: 0,
        usedServicesCount: 0,
        totalShipmentsUsingServices: 0,
        totalRevenueFromServices: 0,
      );
}

/// Entitas satu baris jenis layanan pengiriman dari tabel `m_service_types`
class AdminServiceTypeItem {
  final int id;
  final String kode;
  final String namaLayanan;
  final String? deskripsi;
  final int estimasiHariMin;
  final int estimasiHariMax;
  final bool isActive;
  final num baseTariffPerKg;
  final double insuranceRateDecimal;
  final bool hasCustomTariffColumn;
  final int totalShipmentsCount;
  final int activeShipmentsCount;
  final int deliveredShipmentsCount;
  final num totalRevenueAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminServiceTypeItem({
    required this.id,
    required this.kode,
    required this.namaLayanan,
    this.deskripsi,
    required this.estimasiHariMin,
    required this.estimasiHariMax,
    required this.isActive,
    required this.baseTariffPerKg,
    required this.insuranceRateDecimal,
    this.hasCustomTariffColumn = false,
    this.totalShipmentsCount = 0,
    this.activeShipmentsCount = 0,
    this.deliveredShipmentsCount = 0,
    this.totalRevenueAmount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Format teks estimasi waktu pengiriman
  String get formattedEstimasi {
    if (estimasiHariMin == 0 && estimasiHariMax == 0) {
      return 'Hari yang Sama (Same Day / 6-8 Jam)';
    }
    if (estimasiHariMin == estimasiHariMax) {
      return '$estimasiHariMin Hari Kerja';
    }
    return '$estimasiHariMin - $estimasiHariMax Hari Kerja';
  }

  /// Persentase tarif premi asuransi
  String get formattedInsuranceRate {
    final pct = insuranceRateDecimal * 100.0;
    return '${pct.toStringAsFixed(1)}% dari nilai barang';
  }

  /// Apakah jenis layanan ini sudah pernah digunakan pada transaksi `t_shipments`
  bool get isUsedInShipments => totalShipmentsCount > 0;

  /// Apakah jenis layanan aman untuk dihapus secara fisik dari `m_service_types`
  bool get canBeDeleted => totalShipmentsCount == 0;
}

/// Hasil paginasi daftar jenis layanan beserta statistik ringkasannya
class AdminServiceTypesPaginatedResult {
  final List<AdminServiceTypeItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final AdminServiceTypeSummaryStats summaryStats;

  const AdminServiceTypesPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.summaryStats,
  });

  int get totalPages =>
      totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  static const AdminServiceTypesPaginatedResult empty =
      AdminServiceTypesPaginatedResult(
        items: [],
        totalCount: 0,
        currentPage: 1,
        pageSize: 10,
        summaryStats: AdminServiceTypeSummaryStats.empty,
      );
}

