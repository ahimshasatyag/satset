import 'admin_customer_item.dart';

/// Entitas alamat tambahan customer dari tabel m_address dan relasi m_label + wilayah
class AdminCustomerAddressRecord {
  final int id;
  final int idUsers;
  final String? namaPenerima;
  final String? noHp;
  final String? email;
  final String? labelNama;
  final String alamatLengkap;
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

  const AdminCustomerAddressRecord({
    required this.id,
    required this.idUsers,
    this.namaPenerima,
    this.noHp,
    this.email,
    this.labelNama,
    required this.alamatLengkap,
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
    this.isUtama = false,
    required this.createdAt,
  });

  String get formattedWilayah {
    final parts = <String>[
      if (namaKelurahan != null && namaKelurahan!.isNotEmpty) namaKelurahan!,
      if (namaKecamatan != null && namaKecamatan!.isNotEmpty) namaKecamatan!,
      if (namaKabkot != null && namaKabkot!.isNotEmpty) namaKabkot!,
      if (namaProvinsi != null && namaProvinsi!.isNotEmpty) namaProvinsi!,
      if (kodePos != null && kodePos!.isNotEmpty) kodePos!,
    ];
    return parts.join(', ');
  }
}

/// Kronologi perubahan status paket dari t_shipment_tracking
class AdminCustomerShipmentTrackingStep {
  final int id;
  final String statusKode;
  final String statusNama;
  final String? lokasiNama;
  final String? catatan;
  final DateTime createdAt;

  const AdminCustomerShipmentTrackingStep({
    required this.id,
    required this.statusKode,
    required this.statusNama,
    this.lokasiNama,
    this.catatan,
    required this.createdAt,
  });
}

/// Entitas riwayat pengiriman milik customer dari t_shipments, m_shipment_statuses, m_service_types, t_shipment_payments
class AdminCustomerShipmentRecord {
  final int id;
  final String nomorResi;
  final String barcodeValue;
  final String pengirimNama;
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final String serviceKode;
  final String serviceNama;
  final String statusKode;
  final String statusNama;
  final num totalBeratGram;
  final num biayaPengiriman;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final DateTime createdAt;
  final List<AdminCustomerShipmentTrackingStep> trackingSteps;

  const AdminCustomerShipmentRecord({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    required this.pengirimNama,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    required this.penerimaKota,
    required this.serviceKode,
    required this.serviceNama,
    required this.statusKode,
    required this.statusNama,
    required this.totalBeratGram,
    required this.biayaPengiriman,
    required this.totalBiaya,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.createdAt,
    this.trackingSteps = const [],
  });
}

/// Detail lengkap customer untuk dialog/panel detail pada Admin Customer Management
class AdminCustomerDetail {
  final AdminCustomerItem customer;
  final List<AdminCustomerAddressRecord> additionalAddresses;
  final List<AdminCustomerShipmentRecord> shipments;

  const AdminCustomerDetail({
    required this.customer,
    required this.additionalAddresses,
    required this.shipments,
  });
}

