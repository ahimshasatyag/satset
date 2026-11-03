import 'package:equatable/equatable.dart';
import 'admin_report_filter.dart';

/// Titik data grafik kategorikal / distribusi untuk laporan
class AdminReportChartPoint extends Equatable {
  final String code;
  final String label;
  final int count;
  final num amount;
  final double percentage;

  const AdminReportChartPoint({
    required this.code,
    required this.label,
    required this.count,
    this.amount = 0,
    this.percentage = 0,
  });

  @override
  List<Object?> get props => [code, label, count, amount, percentage];
}

/// Titik data grafik tren waktu (time-series) atau perbandingan metrik
class AdminReportTrendPoint extends Equatable {
  final String label;
  final int primaryCount;
  final int secondaryCount;
  final int tertiaryCount;
  final num totalAmount;

  const AdminReportTrendPoint({
    required this.label,
    required this.primaryCount,
    this.secondaryCount = 0,
    this.tertiaryCount = 0,
    this.totalAmount = 0,
  });

  @override
  List<Object?> get props => [
        label,
        primaryCount,
        secondaryCount,
        tertiaryCount,
        totalAmount,
      ];
}

/// Ringkasan statistik Laporan Operasional Pengiriman (t_shipments & m_shipment_statuses)
class AdminShipmentReportSummary extends Equatable {
  final int totalPackages;
  final int deliveredCount;
  final int inProcessCount;
  final int failedCount;
  final int cancelledCount;
  final int returnedCount;
  final num totalWeightGrams;
  final num totalRevenue;
  final Map<String, int> countByExactStatus;

  const AdminShipmentReportSummary({
    this.totalPackages = 0,
    this.deliveredCount = 0,
    this.inProcessCount = 0,
    this.failedCount = 0,
    this.cancelledCount = 0,
    this.returnedCount = 0,
    this.totalWeightGrams = 0,
    this.totalRevenue = 0,
    this.countByExactStatus = const {},
  });

  double get deliverySuccessRate =>
      totalPackages > 0 ? (deliveredCount / totalPackages) * 100.0 : 0.0;

  static const empty = AdminShipmentReportSummary();

  @override
  List<Object?> get props => [
        totalPackages,
        deliveredCount,
        inProcessCount,
        failedCount,
        cancelledCount,
        returnedCount,
        totalWeightGrams,
        totalRevenue,
        countByExactStatus,
      ];
}

/// Ringkasan statistik Laporan Performa Kurir (m_employee & t_shipment_assignments)
class AdminCourierReportSummary extends Equatable {
  final int totalCouriers;
  final int activeCouriers;
  final int totalAssignedTasks;
  final int deliveredTasks;
  final int inProgressTasks;
  final int failedOrReturnedTasks;
  final int totalProofUploaded;
  final int totalGpsLogs;

  const AdminCourierReportSummary({
    this.totalCouriers = 0,
    this.activeCouriers = 0,
    this.totalAssignedTasks = 0,
    this.deliveredTasks = 0,
    this.inProgressTasks = 0,
    this.failedOrReturnedTasks = 0,
    this.totalProofUploaded = 0,
    this.totalGpsLogs = 0,
  });

  double get averageSuccessRate => totalAssignedTasks > 0
      ? (deliveredTasks / totalAssignedTasks) * 100.0
      : 0.0;

  static const empty = AdminCourierReportSummary();

  @override
  List<Object?> get props => [
        totalCouriers,
        activeCouriers,
        totalAssignedTasks,
        deliveredTasks,
        inProgressTasks,
        failedOrReturnedTasks,
        totalProofUploaded,
        totalGpsLogs,
      ];
}

/// Ringkasan statistik Laporan Aktivitas Pelanggan (m_users & t_shipments)
class AdminCustomerReportSummary extends Equatable {
  final int totalCustomers;
  final int transactingCustomers;
  final int verifiedCustomers;
  final int totalShipments;
  final int completedShipments;
  final num totalTransactionValue;
  final num paidTransactionValue;

  const AdminCustomerReportSummary({
    this.totalCustomers = 0,
    this.transactingCustomers = 0,
    this.verifiedCustomers = 0,
    this.totalShipments = 0,
    this.completedShipments = 0,
    this.totalTransactionValue = 0,
    this.paidTransactionValue = 0,
  });

  static const empty = AdminCustomerReportSummary();

  @override
  List<Object?> get props => [
        totalCustomers,
        transactingCustomers,
        verifiedCustomers,
        totalShipments,
        completedShipments,
        totalTransactionValue,
        paidTransactionValue,
      ];
}

/// Ringkasan statistik Laporan Transaksi Pembayaran (t_shipment_payments)
class AdminPaymentReportSummary extends Equatable {
  final int totalTransactions;
  final num totalNominal;
  final int transferCount;
  final num transferNominal;
  final int codCount;
  final num codNominal;
  final int paidCount;
  final num paidNominal;
  final int pendingCount;
  final num pendingNominal;
  final int failedCount;
  final num failedNominal;
  final int expiredCount;
  final num expiredNominal;

  const AdminPaymentReportSummary({
    this.totalTransactions = 0,
    this.totalNominal = 0,
    this.transferCount = 0,
    this.transferNominal = 0,
    this.codCount = 0,
    this.codNominal = 0,
    this.paidCount = 0,
    this.paidNominal = 0,
    this.pendingCount = 0,
    this.pendingNominal = 0,
    this.failedCount = 0,
    this.failedNominal = 0,
    this.expiredCount = 0,
    this.expiredNominal = 0,
  });

  static const empty = AdminPaymentReportSummary();

  @override
  List<Object?> get props => [
        totalTransactions,
        totalNominal,
        transferCount,
        transferNominal,
        codCount,
        codNominal,
        paidCount,
        paidNominal,
        pendingCount,
        pendingNominal,
        failedCount,
        failedNominal,
        expiredCount,
        expiredNominal,
      ];
}

/// Baris Tabel Laporan Pengiriman (t_shipments)
class AdminShipmentReportRow extends Equatable {
  final int shipmentId;
  final String nomorResi;
  final DateTime? createdAt;
  final String customerNama;
  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaKota;
  final String serviceKode;
  final String serviceNama;
  final String statusKode;
  final String statusNama;
  final int? courierId;
  final String? courierNama;
  final String? courierCode;
  final num totalBeratGram;
  final num biayaPengiriman;
  final num biayaAsuransi;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final int trackingEventsCount;
  final bool hasDeliveryProof;
  final DateTime? deliveredAt;

  const AdminShipmentReportRow({
    required this.shipmentId,
    required this.nomorResi,
    this.createdAt,
    required this.customerNama,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaKota,
    required this.serviceKode,
    required this.serviceNama,
    required this.statusKode,
    required this.statusNama,
    this.courierId,
    this.courierNama,
    this.courierCode,
    required this.totalBeratGram,
    required this.biayaPengiriman,
    required this.biayaAsuransi,
    required this.totalBiaya,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.trackingEventsCount = 0,
    this.hasDeliveryProof = false,
    this.deliveredAt,
  });

  @override
  List<Object?> get props => [
        shipmentId,
        nomorResi,
        createdAt,
        customerNama,
        pengirimNama,
        pengirimKota,
        penerimaNama,
        penerimaKota,
        serviceKode,
        serviceNama,
        statusKode,
        statusNama,
        courierId,
        courierNama,
        courierCode,
        totalBeratGram,
        biayaPengiriman,
        biayaAsuransi,
        totalBiaya,
        metodePembayaran,
        statusPembayaran,
        trackingEventsCount,
        hasDeliveryProof,
        deliveredAt,
      ];
}

/// Baris Tabel Laporan Performa Kurir (m_employee & t_shipment_assignments)
class AdminCourierReportRow extends Equatable {
  final int courierId;
  final String employeeCode;
  final String namaLengkap;
  final String email;
  final String noHp;
  final bool isActive;
  final int totalAssigned;
  final int deliveredCount;
  final int inProgressCount;
  final int failedOrReturnedCount;
  final int cancelledCount;
  final int trackingUpdatesCount;
  final int proofUploadedCount;
  final int gpsLocationsCount;
  final num totalCodHandled;
  final DateTime? lastAssignmentAt;
  final DateTime? lastGpsRecordedAt;

  const AdminCourierReportRow({
    required this.courierId,
    required this.employeeCode,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    required this.isActive,
    required this.totalAssigned,
    required this.deliveredCount,
    required this.inProgressCount,
    required this.failedOrReturnedCount,
    this.cancelledCount = 0,
    this.trackingUpdatesCount = 0,
    this.proofUploadedCount = 0,
    this.gpsLocationsCount = 0,
    this.totalCodHandled = 0,
    this.lastAssignmentAt,
    this.lastGpsRecordedAt,
  });

  double get completionRate =>
      totalAssigned > 0 ? (deliveredCount / totalAssigned) * 100.0 : 0.0;

  @override
  List<Object?> get props => [
        courierId,
        employeeCode,
        namaLengkap,
        email,
        noHp,
        isActive,
        totalAssigned,
        deliveredCount,
        inProgressCount,
        failedOrReturnedCount,
        cancelledCount,
        trackingUpdatesCount,
        proofUploadedCount,
        gpsLocationsCount,
        totalCodHandled,
        lastAssignmentAt,
        lastGpsRecordedAt,
      ];
}

/// Baris Tabel Laporan Pelanggan (m_users & t_shipments) - Tanpa Data Sensitif
class AdminCustomerReportRow extends Equatable {
  final int customerId;
  final String namaLengkap;
  final String email;
  final String noHp;
  final bool emailVerified;
  final DateTime? registeredAt;
  final int totalShipments;
  final int deliveredShipments;
  final int activeShipments;
  final int failedOrCancelledShipments;
  final int transferPaymentsCount;
  final int codPaymentsCount;
  final num totalShippingSpend;
  final num paidShippingSpend;
  final DateTime? lastShipmentAt;

  const AdminCustomerReportRow({
    required this.customerId,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    required this.emailVerified,
    this.registeredAt,
    required this.totalShipments,
    required this.deliveredShipments,
    required this.activeShipments,
    required this.failedOrCancelledShipments,
    this.transferPaymentsCount = 0,
    this.codPaymentsCount = 0,
    required this.totalShippingSpend,
    required this.paidShippingSpend,
    this.lastShipmentAt,
  });

  String get preferredPaymentMethod {
    if (transferPaymentsCount == 0 && codPaymentsCount == 0) return '-';
    return transferPaymentsCount >= codPaymentsCount ? 'TRANSFER' : 'COD';
  }

  @override
  List<Object?> get props => [
        customerId,
        namaLengkap,
        email,
        noHp,
        emailVerified,
        registeredAt,
        totalShipments,
        deliveredShipments,
        activeShipments,
        failedOrCancelledShipments,
        transferPaymentsCount,
        codPaymentsCount,
        totalShippingSpend,
        paidShippingSpend,
        lastShipmentAt,
      ];
}

/// Baris Tabel Laporan Transaksi Pembayaran (t_shipment_payments & t_shipments)
class AdminPaymentReportRow extends Equatable {
  final int paymentId;
  final int shipmentId;
  final String nomorPembayaran;
  final String nomorResi;
  final String customerNama;
  final String serviceKode;
  final String serviceNama;
  final String shipmentStatusKode;
  final String shipmentStatusNama;
  final String? courierNama;
  final String metodePembayaran;
  final String statusPembayaran;
  final String? provider;
  final String? providerReference;
  final num totalBiayaShipment;
  final num jumlahBayar;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? expiredAt;

  const AdminPaymentReportRow({
    required this.paymentId,
    required this.shipmentId,
    required this.nomorPembayaran,
    required this.nomorResi,
    required this.customerNama,
    required this.serviceKode,
    required this.serviceNama,
    required this.shipmentStatusKode,
    required this.shipmentStatusNama,
    this.courierNama,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.provider,
    this.providerReference,
    required this.totalBiayaShipment,
    required this.jumlahBayar,
    this.createdAt,
    this.paidAt,
    this.expiredAt,
  });

  @override
  List<Object?> get props => [
        paymentId,
        shipmentId,
        nomorPembayaran,
        nomorResi,
        customerNama,
        serviceKode,
        serviceNama,
        shipmentStatusKode,
        shipmentStatusNama,
        courierNama,
        metodePembayaran,
        statusPembayaran,
        provider,
        providerReference,
        totalBiayaShipment,
        jumlahBayar,
        createdAt,
        paidAt,
        expiredAt,
      ];
}

/// Hasil terpadu laporan Admin sesuai jenis laporan & filter aktif
class AdminReportDataResult extends Equatable {
  final String reportType;
  final AdminReportFilter appliedFilter;

  // Ringkasan per kategori
  final AdminShipmentReportSummary shipmentSummary;
  final AdminCourierReportSummary courierSummary;
  final AdminCustomerReportSummary customerSummary;
  final AdminPaymentReportSummary paymentSummary;

  // Visualisasi Grafik
  final List<AdminReportChartPoint> distributionChart;
  final List<AdminReportChartPoint> secondaryDistributionChart;
  final List<AdminReportTrendPoint> trendChart;

  // Data Baris Tabel (Paginated)
  final List<AdminShipmentReportRow> shipmentRows;
  final List<AdminCourierReportRow> courierRows;
  final List<AdminCustomerReportRow> customerRows;
  final List<AdminPaymentReportRow> paymentRows;

  // Seluruh baris sesuai filter untuk keperluan Ekspor (CSV, Excel, PDF) & Total
  final List<AdminShipmentReportRow> allFilteredShipmentRows;
  final List<AdminCourierReportRow> allFilteredCourierRows;
  final List<AdminCustomerReportRow> allFilteredCustomerRows;
  final List<AdminPaymentReportRow> allFilteredPaymentRows;

  // Metadata Paginasi & Total Filter
  final int totalFilteredCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final num filteredTotalAmount;
  final num filteredSecondaryTotal;

  const AdminReportDataResult({
    this.reportType = AdminReportType.shipment,
    this.appliedFilter = const AdminReportFilter(),
    this.shipmentSummary = AdminShipmentReportSummary.empty,
    this.courierSummary = AdminCourierReportSummary.empty,
    this.customerSummary = AdminCustomerReportSummary.empty,
    this.paymentSummary = AdminPaymentReportSummary.empty,
    this.distributionChart = const [],
    this.secondaryDistributionChart = const [],
    this.trendChart = const [],
    this.shipmentRows = const [],
    this.courierRows = const [],
    this.customerRows = const [],
    this.paymentRows = const [],
    this.allFilteredShipmentRows = const [],
    this.allFilteredCourierRows = const [],
    this.allFilteredCustomerRows = const [],
    this.allFilteredPaymentRows = const [],
    this.totalFilteredCount = 0,
    this.currentPage = 1,
    this.pageSize = 10,
    this.totalPages = 1,
    this.filteredTotalAmount = 0,
    this.filteredSecondaryTotal = 0,
  });

  static const empty = AdminReportDataResult();

  @override
  List<Object?> get props => [
        reportType,
        appliedFilter,
        shipmentSummary,
        courierSummary,
        customerSummary,
        paymentSummary,
        distributionChart,
        secondaryDistributionChart,
        trendChart,
        shipmentRows,
        courierRows,
        customerRows,
        paymentRows,
        allFilteredShipmentRows,
        allFilteredCourierRows,
        allFilteredCustomerRows,
        allFilteredPaymentRows,
        totalFilteredCount,
        currentPage,
        pageSize,
        totalPages,
        filteredTotalAmount,
        filteredSecondaryTotal,
      ];
}

