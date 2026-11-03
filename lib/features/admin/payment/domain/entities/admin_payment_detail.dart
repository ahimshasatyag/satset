import 'admin_payment_item.dart';

/// Catatan riwayat audit / aktivitas terkait pembayaran dan pengiriman (`t_shipment_tracking` & `t_notifications`)
class AdminPaymentAuditLog {
  final int id;
  final String title;
  final String description;
  final String source;
  final String? actorName;
  final DateTime? createdAt;

  const AdminPaymentAuditLog({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    this.actorName,
    this.createdAt,
  });
}

/// Detail lengkap satu transaksi pembayaran pada panel/modal detail Admin Payment Management
class AdminPaymentDetail {
  final AdminPaymentItem payment;
  final int totalBeratGram;
  final int totalBarang;
  final num nilaiBarang;
  final String? catatanPengiriman;
  final String? courierNama;
  final String? courierNoHp;
  final DateTime? deliveredAt;
  final List<AdminBankReference> availableBanks;
  final List<AdminPaymentAuditLog> auditLogs;

  const AdminPaymentDetail({
    required this.payment,
    required this.totalBeratGram,
    required this.totalBarang,
    required this.nilaiBarang,
    this.catatanPengiriman,
    this.courierNama,
    this.courierNoHp,
    this.deliveredAt,
    this.availableBanks = const [],
    this.auditLogs = const [],
  });
}

