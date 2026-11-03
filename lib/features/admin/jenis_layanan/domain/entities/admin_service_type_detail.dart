import 'admin_service_type_item.dart';

/// Ringkasan transaksi pengiriman (`t_shipments`) yang menggunakan jenis layanan tertentu
class AdminServiceShipmentUsageRecord {
  final int shipmentId;
  final String nomorResi;
  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaKota;
  final int totalBeratGram;
  final num biayaPengiriman;
  final num totalBiaya;
  final String statusKode;
  final String statusNama;
  final DateTime? createdAt;

  const AdminServiceShipmentUsageRecord({
    required this.shipmentId,
    required this.nomorResi,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaKota,
    required this.totalBeratGram,
    required this.biayaPengiriman,
    required this.totalBiaya,
    required this.statusKode,
    required this.statusNama,
    this.createdAt,
  });
}

/// Detail lengkap satu jenis layanan (`m_service_types`) beserta riwayat penggunaannya pada `t_shipments`
class AdminServiceTypeDetail {
  final AdminServiceTypeItem serviceType;
  final List<AdminServiceShipmentUsageRecord> recentShipments;

  const AdminServiceTypeDetail({
    required this.serviceType,
    this.recentShipments = const [],
  });
}

