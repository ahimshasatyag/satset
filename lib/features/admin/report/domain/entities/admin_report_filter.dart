import 'package:equatable/equatable.dart';

/// Jenis laporan yang tersedia pada halaman Admin Report SatSet Delivery
class AdminReportType {
  AdminReportType._();

  static const String shipment = 'SHIPMENT';
  static const String courier = 'COURIER';
  static const String customer = 'CUSTOMER';
  static const String payment = 'PAYMENT';

  static const List<String> allValues = [
    shipment,
    courier,
    customer,
    payment,
  ];

  static String labelOf(String type) {
    switch (type.toUpperCase()) {
      case shipment:
        return 'Laporan Pengiriman';
      case courier:
        return 'Laporan Performa Kurir';
      case customer:
        return 'Laporan Aktivitas Pelanggan';
      case payment:
        return 'Laporan Transaksi Pembayaran';
      default:
        return 'Laporan Pengiriman';
    }
  }
}

/// Format ekspor laporan yang didukung
enum AdminReportExportFormat {
  csv,
  excel,
  pdf,
}

/// Opsi referensi filter dari database (Status, Layanan, Kurir)
class AdminReportFilterReference extends Equatable {
  final String id;
  final String code;
  final String label;

  const AdminReportFilterReference({
    required this.id,
    required this.code,
    required this.label,
  });

  @override
  List<Object?> get props => [id, code, label];
}

/// Kumpulan daftar referensi untuk dropdown filter halaman laporan
class AdminReportFilterReferences extends Equatable {
  final List<AdminReportFilterReference> shipmentStatuses;
  final List<AdminReportFilterReference> serviceTypes;
  final List<AdminReportFilterReference> couriers;

  const AdminReportFilterReferences({
    this.shipmentStatuses = const [],
    this.serviceTypes = const [],
    this.couriers = const [],
  });

  static const empty = AdminReportFilterReferences();

  @override
  List<Object?> get props => [shipmentStatuses, serviceTypes, couriers];
}

/// Parameter filter dan pengurutan laporan
class AdminReportFilter extends Equatable {
  final String reportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shipmentStatusCode;
  final String? serviceTypeCode;
  final String? paymentMethod;
  final String? paymentStatus;
  final int? courierId;
  final String searchQuery;
  final String sortColumn;
  final bool sortAscending;
  final int page;
  final int pageSize;

  const AdminReportFilter({
    this.reportType = AdminReportType.shipment,
    this.startDate,
    this.endDate,
    this.shipmentStatusCode,
    this.serviceTypeCode,
    this.paymentMethod,
    this.paymentStatus,
    this.courierId,
    this.searchQuery = '',
    this.sortColumn = 'created_at',
    this.sortAscending = false,
    this.page = 1,
    this.pageSize = 10,
  });

  /// Validasi rentang tanggal: memastikan startDate tidak lebih besar dari endDate
  String? validateDateRange() {
    if (startDate != null && endDate != null) {
      final normalizedStart = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      );
      final normalizedEnd = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
      );
      if (normalizedStart.isAfter(normalizedEnd)) {
        return 'Tanggal mulai tidak boleh melebihi tanggal akhir.';
      }
    }
    return null;
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      (shipmentStatusCode != null &&
          shipmentStatusCode!.isNotEmpty &&
          shipmentStatusCode != 'ALL') ||
      (serviceTypeCode != null &&
          serviceTypeCode!.isNotEmpty &&
          serviceTypeCode != 'ALL') ||
      (paymentMethod != null &&
          paymentMethod!.isNotEmpty &&
          paymentMethod != 'ALL') ||
      (paymentStatus != null &&
          paymentStatus!.isNotEmpty &&
          paymentStatus != 'ALL') ||
      courierId != null ||
      searchQuery.trim().isNotEmpty;

  AdminReportFilter copyWith({
    String? reportType,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? shipmentStatusCode,
    bool clearShipmentStatus = false,
    String? serviceTypeCode,
    bool clearServiceType = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    String? paymentStatus,
    bool clearPaymentStatus = false,
    int? courierId,
    bool clearCourierId = false,
    String? searchQuery,
    String? sortColumn,
    bool? sortAscending,
    int? page,
    int? pageSize,
  }) {
    return AdminReportFilter(
      reportType: reportType ?? this.reportType,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      shipmentStatusCode: clearShipmentStatus
          ? null
          : (shipmentStatusCode ?? this.shipmentStatusCode),
      serviceTypeCode:
          clearServiceType ? null : (serviceTypeCode ?? this.serviceTypeCode),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      paymentStatus:
          clearPaymentStatus ? null : (paymentStatus ?? this.paymentStatus),
      courierId: clearCourierId ? null : (courierId ?? this.courierId),
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        reportType,
        startDate,
        endDate,
        shipmentStatusCode,
        serviceTypeCode,
        paymentMethod,
        paymentStatus,
        courierId,
        searchQuery,
        sortColumn,
        sortAscending,
        page,
        pageSize,
      ];
}

