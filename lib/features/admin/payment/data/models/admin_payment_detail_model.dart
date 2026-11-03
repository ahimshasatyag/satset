import '../../domain/entities/admin_payment_detail.dart';
import '../../domain/entities/admin_payment_item.dart';

class AdminPaymentAuditLogModel extends AdminPaymentAuditLog {
  const AdminPaymentAuditLogModel({
    required super.id,
    required super.title,
    required super.description,
    required super.source,
    super.actorName,
    super.createdAt,
  });

  factory AdminPaymentAuditLogModel.fromTrackingMap(
    Map<String, dynamic> map, {
    String? statusLabel,
    String? actorName,
  }) {
    final catatan = (map['catatan'] ?? '').toString();
    final lokasi = (map['lokasi_nama'] ?? '').toString();
    final source = (map['event_source'] ?? 'SYSTEM').toString();

    return AdminPaymentAuditLogModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      title: statusLabel ?? 'Aktivitas Pengiriman & Pembayaran',
      description: catatan.isNotEmpty
          ? (lokasi.isNotEmpty ? '$catatan ($lokasi)' : catatan)
          : (lokasi.isNotEmpty ? lokasi : 'Pembaruan tercatat pada sistem.'),
      source: source,
      actorName: actorName,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  factory AdminPaymentAuditLogModel.fromNotificationMap(
    Map<String, dynamic> map,
  ) {
    return AdminPaymentAuditLogModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      title: (map['judul'] ?? 'Notifikasi Transaksi').toString(),
      description: (map['pesan'] ?? '-').toString(),
      source: (map['tipe'] ?? 'NOTIFICATION').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class AdminPaymentDetailModel extends AdminPaymentDetail {
  const AdminPaymentDetailModel({
    required super.payment,
    required super.totalBeratGram,
    required super.totalBarang,
    required super.nilaiBarang,
    super.catatanPengiriman,
    super.courierNama,
    super.courierNoHp,
    super.deliveredAt,
    super.availableBanks = const [],
    super.auditLogs = const [],
  });

  factory AdminPaymentDetailModel.fromData({
    required AdminPaymentItem payment,
    required Map<String, dynamic> shipmentMap,
    String? courierNama,
    String? courierNoHp,
    List<AdminBankReference> availableBanks = const [],
    List<AdminPaymentAuditLog> auditLogs = const [],
  }) {
    return AdminPaymentDetailModel(
      payment: payment,
      totalBeratGram:
          int.tryParse(shipmentMap['total_berat_gram']?.toString() ?? '0') ?? 0,
      totalBarang:
          int.tryParse(shipmentMap['total_barang']?.toString() ?? '1') ?? 1,
      nilaiBarang:
          num.tryParse(shipmentMap['nilai_barang']?.toString() ?? '0') ?? 0,
      catatanPengiriman: shipmentMap['catatan_pengiriman']?.toString(),
      courierNama: courierNama,
      courierNoHp: courierNoHp,
      deliveredAt: shipmentMap['delivered_at'] != null
          ? DateTime.tryParse(shipmentMap['delivered_at'].toString())
          : null,
      availableBanks: availableBanks,
      auditLogs: auditLogs,
    );
  }
}

