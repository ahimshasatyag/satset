import 'package:equatable/equatable.dart';

/// Entity metrik statistik keseluruhan dashboard admin
class AdminDashboardStats extends Equatable {
  // Pengiriman (t_shipments & m_shipment_statuses)
  final int totalShipments;
  final int pendingShipments;
  final int inProcessShipments;
  final int deliveredShipments;
  final int failedShipments;
  final int cancelledShipments;

  // Pengguna & Pegawai (m_users, m_employee)
  final int totalCustomers;
  final int totalEmployees;
  final int totalAdmins;
  final int totalCouriers;
  final int activeCouriersCount;
  final int couriersWithAssignmentCount;

  // Distribusi Status & Tren
  final List<AdminStatusDistribution> statusDistributions;
  final List<AdminTrendPoint> dailyTrends;
  final List<AdminTrendPoint> weeklyTrends;
  final List<AdminTrendPoint> monthlyTrends;

  // Ringkasan Pembayaran (t_shipment_payments)
  final AdminPaymentSummary paymentSummary;

  const AdminDashboardStats({
    required this.totalShipments,
    required this.pendingShipments,
    required this.inProcessShipments,
    required this.deliveredShipments,
    required this.failedShipments,
    required this.cancelledShipments,
    required this.totalCustomers,
    required this.totalEmployees,
    required this.totalAdmins,
    required this.totalCouriers,
    required this.activeCouriersCount,
    required this.couriersWithAssignmentCount,
    required this.statusDistributions,
    required this.dailyTrends,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.paymentSummary,
  });

  static const empty = AdminDashboardStats(
    totalShipments: 0,
    pendingShipments: 0,
    inProcessShipments: 0,
    deliveredShipments: 0,
    failedShipments: 0,
    cancelledShipments: 0,
    totalCustomers: 0,
    totalEmployees: 0,
    totalAdmins: 0,
    totalCouriers: 0,
    activeCouriersCount: 0,
    couriersWithAssignmentCount: 0,
    statusDistributions: [],
    dailyTrends: [],
    weeklyTrends: [],
    monthlyTrends: [],
    paymentSummary: AdminPaymentSummary.empty,
  );

  @override
  List<Object?> get props => [
        totalShipments,
        pendingShipments,
        inProcessShipments,
        deliveredShipments,
        failedShipments,
        cancelledShipments,
        totalCustomers,
        totalEmployees,
        totalAdmins,
        totalCouriers,
        activeCouriersCount,
        couriersWithAssignmentCount,
        statusDistributions,
        dailyTrends,
        weeklyTrends,
        monthlyTrends,
        paymentSummary,
      ];
}

/// Entity item distribusi status pengiriman
class AdminStatusDistribution extends Equatable {
  final String statusCode;
  final String statusName;
  final int count;
  final double percentage;

  const AdminStatusDistribution({
    required this.statusCode,
    required this.statusName,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [statusCode, statusName, count, percentage];
}

/// Entity titik tren data grafik pengiriman
class AdminTrendPoint extends Equatable {
  final String label;
  final int total;
  final int delivered;
  final int failed;

  const AdminTrendPoint({
    required this.label,
    required this.total,
    required this.delivered,
    required this.failed,
  });

  @override
  List<Object?> get props => [label, total, delivered, failed];
}

/// Entity ringkasan transaksi pembayaran
class AdminPaymentSummary extends Equatable {
  final num totalAmount;
  final num paidAmount;
  final num pendingAmount;
  final num codAmount;
  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final int codCount;

  const AdminPaymentSummary({
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.codAmount,
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.codCount,
  });

  static const empty = AdminPaymentSummary(
    totalAmount: 0,
    paidAmount: 0,
    pendingAmount: 0,
    codAmount: 0,
    totalCount: 0,
    paidCount: 0,
    pendingCount: 0,
    codCount: 0,
  );

  @override
  List<Object?> get props => [
        totalAmount,
        paidAmount,
        pendingAmount,
        codAmount,
        totalCount,
        paidCount,
        pendingCount,
        codCount,
      ];
}

