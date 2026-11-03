/// Tab pengelompokan status dan metode pembayaran pada halaman Admin Payment Management
class AdminPaymentTab {
  AdminPaymentTab._();

  static const String all = 'ALL';
  static const String pending = 'PENDING';
  static const String paid = 'PAID';
  static const String failed = 'FAILED';
  static const String expired = 'EXPIRED';
  static const String cod = 'COD';
}

/// Periode ringkasan dan grafik analitik pembayaran
enum AdminPaymentPeriod {
  daily,
  weekly,
  monthly,
}

/// Informasi master jenis bank (`m_jenis_bank`) dan rekening bank (`m_bank`)
class AdminBankReference {
  final String bankId;
  final String namaPemilik;
  final String nomorRekening;
  final String jenisBankId;
  final String namaJenisBank;
  final DateTime? createdAt;

  const AdminBankReference({
    required this.bankId,
    required this.namaPemilik,
    required this.nomorRekening,
    required this.jenisBankId,
    required this.namaJenisBank,
    this.createdAt,
  });

  String get displayLabel =>
      namaJenisBank.isNotEmpty ? 'Bank $namaJenisBank ($nomorRekening - a.n. $namaPemilik)' : nomorRekening;
}

/// Titik data grafik tren pembayaran per periode (Harian, Mingguan, Bulanan)
class AdminPaymentTrendPoint {
  final String label;
  final num totalAmount;
  final num paidAmount;
  final num pendingAmount;
  final num codAmount;
  final int transactionCount;
  final int paidCount;

  const AdminPaymentTrendPoint({
    required this.label,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.codAmount,
    required this.transactionCount,
    required this.paidCount,
  });
}

/// Distribusi pembayaran berdasarkan metode atau status atau bank
class AdminPaymentDistributionItem {
  final String code;
  final String label;
  final int count;
  final num totalAmount;
  final double percentage;

  const AdminPaymentDistributionItem({
    required this.code,
    required this.label,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });
}

/// Statistik ringkasan menyeluruh transaksi pembayaran (`t_shipment_payments`)
class AdminPaymentSummaryStats {
  final int totalTransactions;
  final num totalAmount;

  final int paidCount;
  final num paidAmount;

  final int pendingCount;
  final num pendingAmount;

  final int failedCount;
  final num failedAmount;

  final int expiredCount;
  final num expiredAmount;

  final int codTotalCount;
  final num codTotalAmount;

  final int codSettledCount;
  final num codSettledAmount;

  final int codUnsettledCount;
  final num codUnsettledAmount;

  final List<AdminPaymentTrendPoint> dailyTrends;
  final List<AdminPaymentTrendPoint> weeklyTrends;
  final List<AdminPaymentTrendPoint> monthlyTrends;
  final List<AdminPaymentDistributionItem> methodDistribution;
  final List<AdminPaymentDistributionItem> statusDistribution;

  const AdminPaymentSummaryStats({
    required this.totalTransactions,
    required this.totalAmount,
    required this.paidCount,
    required this.paidAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.failedCount,
    required this.failedAmount,
    required this.expiredCount,
    required this.expiredAmount,
    required this.codTotalCount,
    required this.codTotalAmount,
    required this.codSettledCount,
    required this.codSettledAmount,
    required this.codUnsettledCount,
    required this.codUnsettledAmount,
    this.dailyTrends = const [],
    this.weeklyTrends = const [],
    this.monthlyTrends = const [],
    this.methodDistribution = const [],
    this.statusDistribution = const [],
  });

  static const AdminPaymentSummaryStats empty = AdminPaymentSummaryStats(
    totalTransactions: 0,
    totalAmount: 0,
    paidCount: 0,
    paidAmount: 0,
    pendingCount: 0,
    pendingAmount: 0,
    failedCount: 0,
    failedAmount: 0,
    expiredCount: 0,
    expiredAmount: 0,
    codTotalCount: 0,
    codTotalAmount: 0,
    codSettledCount: 0,
    codSettledAmount: 0,
    codUnsettledCount: 0,
    codUnsettledAmount: 0,
  );
}

/// Entitas baris daftar transaksi pembayaran pada tabel Admin Payment Management
class AdminPaymentItem {
  final int id;
  final int shipmentId;
  final String nomorPembayaran;
  final String nomorResi;
  final String barcodeValue;

  final int? customerId;
  final String customerNama;
  final String customerEmail;
  final String customerNoHp;

  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaKota;
  final String penerimaAlamat;

  final int? serviceTypeId;
  final String serviceKode;
  final String serviceNama;

  final int? shipmentStatusId;
  final String shipmentStatusKode;
  final String shipmentStatusNama;

  final num biayaPengiriman;
  final num biayaAsuransi;
  final num biayaLayananTambahan;
  final num diskon;
  final num totalBiayaShipment;

  final String metodePembayaran;
  final String statusPembayaran;
  final num jumlahBayar;
  final String? provider;
  final String? providerReference;
  final String? buktiPembayaranPath;

  final String? jenisBankId;
  final String? namaJenisBank;
  final String? namaPemilikRekening;
  final String? nomorRekeningBank;

  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminPaymentItem({
    required this.id,
    required this.shipmentId,
    required this.nomorPembayaran,
    required this.nomorResi,
    required this.barcodeValue,
    this.customerId,
    required this.customerNama,
    required this.customerEmail,
    required this.customerNoHp,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaKota,
    required this.penerimaAlamat,
    this.serviceTypeId,
    required this.serviceKode,
    required this.serviceNama,
    this.shipmentStatusId,
    required this.shipmentStatusKode,
    required this.shipmentStatusNama,
    required this.biayaPengiriman,
    required this.biayaAsuransi,
    required this.biayaLayananTambahan,
    required this.diskon,
    required this.totalBiayaShipment,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.jumlahBayar,
    this.provider,
    this.providerReference,
    this.buktiPembayaranPath,
    this.jenisBankId,
    this.namaJenisBank,
    this.namaPemilikRekening,
    this.nomorRekeningBank,
    this.paidAt,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Apakah transaksi menggunakan metode Cash on Delivery (COD)
  bool get isCod =>
      metodePembayaran.toUpperCase() == 'COD' ||
      statusPembayaran.toUpperCase() == 'COD';

  /// Apakah pembayaran sudah lunas / terverifikasi berhasil
  bool get isPaid {
    final s = statusPembayaran.toUpperCase();
    return s == 'PAID' || s == 'SUCCESS' || s == 'BERHASIL' || s == 'SETTLED';
  }

  /// Apakah pembayaran masih menunggu penyelesaian
  bool get isPending {
    final s = statusPembayaran.toUpperCase();
    return s == 'PENDING' || s == 'MENUNGGU' || (s == 'COD' && paidAt == null);
  }

  /// Apakah pembayaran gagal
  bool get isFailed {
    final s = statusPembayaran.toUpperCase();
    return s == 'FAILED' || s == 'GAGAL';
  }

  /// Apakah pembayaran telah melewati batas waktu (`expired_at`) atau berstatus `EXPIRED`
  bool get isExpired {
    final s = statusPembayaran.toUpperCase();
    if (s == 'EXPIRED' || s == 'KADALUARSA') return true;
    if (!isPaid && !isCod && expiredAt != null) {
      return DateTime.now().isAfter(expiredAt!);
    }
    return false;
  }

  /// Status aktual yang dinormalisasi (`PAID`, `PENDING`, `FAILED`, `EXPIRED`)
  String get normalizedStatus {
    if (isPaid) return 'PAID';
    if (isFailed) return 'FAILED';
    if (isExpired) return 'EXPIRED';
    return 'PENDING';
  }

  /// Apakah nominal pada `t_shipment_payments.jumlah_bayar` sesuai dengan `t_shipments.total_biaya`
  bool get isAmountMatched =>
      (jumlahBayar - totalBiayaShipment).abs() < 1.0;

  /// Apakah transaksi COD sudah diselesaikan / disetor
  bool get isCodSettled => isCod && isPaid;
}

/// Hasil paginasi daftar transaksi pembayaran beserta statistik dan referensi bank
class AdminPaymentsPaginatedResult {
  final List<AdminPaymentItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final AdminPaymentSummaryStats summaryStats;
  final Map<String, int> tabCounts;
  final List<AdminBankReference> bankReferences;

  const AdminPaymentsPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.summaryStats,
    required this.tabCounts,
    this.bankReferences = const [],
  });

  int get totalPages =>
      totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  static const AdminPaymentsPaginatedResult empty =
      AdminPaymentsPaginatedResult(
        items: [],
        totalCount: 0,
        currentPage: 1,
        pageSize: 10,
        summaryStats: AdminPaymentSummaryStats.empty,
        tabCounts: {
          AdminPaymentTab.all: 0,
          AdminPaymentTab.pending: 0,
          AdminPaymentTab.paid: 0,
          AdminPaymentTab.failed: 0,
          AdminPaymentTab.expired: 0,
          AdminPaymentTab.cod: 0,
        },
      );
}

