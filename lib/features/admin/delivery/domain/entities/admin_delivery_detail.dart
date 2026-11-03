import 'package:equatable/equatable.dart';

/// Entitas lengkap detail pengiriman beserta customer, pembayaran, penugasan kurir,
/// riwayat pelacakan (`t_shipment_tracking`), dan lokasi terakhir kurir (`t_shipment_locations`).
class AdminDeliveryDetail extends Equatable {
  final int id;
  final String nomorResi;
  final String barcodeValue;
  final int? statusId;
  final String statusKode;
  final String statusNama;
  final int? serviceTypeId;
  final String serviceKode;
  final String serviceNama;
  final String? serviceEstimasi;

  // Profil Customer (dari m_users)
  final int? customerId;
  final String customerNama;
  final String customerEmail;
  final String customerNoHp;

  // Pengirim
  final String pengirimNama;
  final String pengirimNoHp;
  final String pengirimAlamat;
  final String pengirimKota;
  final String? pengirimKodePos;
  final double? pengirimLatitude;
  final double? pengirimLongitude;

  // Penerima
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final String? penerimaKodePos;
  final double? penerimaLatitude;
  final double? penerimaLongitude;

  // Spesifikasi Paket
  final num totalBeratGram;
  final num panjangCm;
  final num lebarCm;
  final num tinggiCm;
  final int totalBarang;
  final num? nilaiBarang;
  final String? catatanPengiriman;

  // Rincian Biaya & Pembayaran (dari t_shipments & t_shipment_payments)
  final num biayaPengiriman;
  final num biayaAsuransi;
  final num biayaLayananTambahan;
  final num diskon;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final String? nomorPembayaran;
  final String? providerPembayaran;
  final DateTime? paidAt;

  // Penugasan Kurir Aktif (dari t_shipment_assignments & m_employee)
  final int? assignmentId;
  final int? courierId;
  final String? courierNama;
  final String? courierCode;
  final String? courierEmail;
  final String? courierPhone;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? assignmentNotes;

  // Lokasi Terakhir Kurir (dari t_shipment_locations)
  final AdminCourierLocationPoint? lastCourierLocation;

  // Waktu Penting
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? estimasiTiba;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  // Kronologi Riwayat Tracking (dari t_shipment_tracking)
  final List<AdminDeliveryTrackingItem> trackingHistory;

  const AdminDeliveryDetail({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    this.statusId,
    required this.statusKode,
    required this.statusNama,
    this.serviceTypeId,
    required this.serviceKode,
    required this.serviceNama,
    this.serviceEstimasi,
    this.customerId,
    required this.customerNama,
    required this.customerEmail,
    required this.customerNoHp,
    required this.pengirimNama,
    required this.pengirimNoHp,
    required this.pengirimAlamat,
    required this.pengirimKota,
    this.pengirimKodePos,
    this.pengirimLatitude,
    this.pengirimLongitude,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    required this.penerimaKota,
    this.penerimaKodePos,
    this.penerimaLatitude,
    this.penerimaLongitude,
    required this.totalBeratGram,
    required this.panjangCm,
    required this.lebarCm,
    required this.tinggiCm,
    required this.totalBarang,
    this.nilaiBarang,
    this.catatanPengiriman,
    required this.biayaPengiriman,
    required this.biayaAsuransi,
    required this.biayaLayananTambahan,
    required this.diskon,
    required this.totalBiaya,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.nomorPembayaran,
    this.providerPembayaran,
    this.paidAt,
    this.assignmentId,
    this.courierId,
    this.courierNama,
    this.courierCode,
    this.courierEmail,
    this.courierPhone,
    this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    this.assignmentNotes,
    this.lastCourierLocation,
    this.createdAt,
    this.updatedAt,
    this.estimasiTiba,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.trackingHistory,
  });

  bool get hasActiveCourier => courierId != null && courierId! > 0;

  bool get isCourierOnActiveDuty =>
      hasActiveCourier &&
      completedAt == null &&
      statusKode.toUpperCase() != 'DELIVERED' &&
      statusKode.toUpperCase() != 'CANCELLED';

  @override
  List<Object?> get props => [
        id,
        nomorResi,
        barcodeValue,
        statusId,
        statusKode,
        statusNama,
        serviceTypeId,
        serviceKode,
        serviceNama,
        serviceEstimasi,
        customerId,
        customerNama,
        customerEmail,
        customerNoHp,
        pengirimNama,
        pengirimNoHp,
        pengirimAlamat,
        pengirimKota,
        pengirimKodePos,
        pengirimLatitude,
        pengirimLongitude,
        penerimaNama,
        penerimaNoHp,
        penerimaAlamat,
        penerimaKota,
        penerimaKodePos,
        penerimaLatitude,
        penerimaLongitude,
        totalBeratGram,
        panjangCm,
        lebarCm,
        tinggiCm,
        totalBarang,
        nilaiBarang,
        catatanPengiriman,
        biayaPengiriman,
        biayaAsuransi,
        biayaLayananTambahan,
        diskon,
        totalBiaya,
        metodePembayaran,
        statusPembayaran,
        nomorPembayaran,
        providerPembayaran,
        paidAt,
        assignmentId,
        courierId,
        courierNama,
        courierCode,
        courierEmail,
        courierPhone,
        assignedAt,
        acceptedAt,
        completedAt,
        assignmentNotes,
        lastCourierLocation,
        createdAt,
        updatedAt,
        estimasiTiba,
        pickedUpAt,
        deliveredAt,
        cancelledAt,
        trackingHistory,
      ];
}

/// Kronologi perjalanan paket dari `t_shipment_tracking`
class AdminDeliveryTrackingItem extends Equatable {
  final int id;
  final int? statusId;
  final String statusCode;
  final String statusName;
  final String? lokasiNama;
  final String? catatan;
  final String? employeeName;
  final String? eventSource;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const AdminDeliveryTrackingItem({
    required this.id,
    this.statusId,
    required this.statusCode,
    required this.statusName,
    this.lokasiNama,
    this.catatan,
    this.employeeName,
    this.eventSource,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        statusId,
        statusCode,
        statusName,
        lokasiNama,
        catatan,
        employeeName,
        eventSource,
        latitude,
        longitude,
        createdAt,
      ];
}

/// Titik koordinat lokasi terakhir kurir dari `t_shipment_locations`
class AdminCourierLocationPoint extends Equatable {
  final int id;
  final int? shipmentId;
  final int courierId;
  final double latitude;
  final double longitude;
  final double? speedMps;
  final double? heading;
  final double? accuracyM;
  final DateTime? recordedAt;

  const AdminCourierLocationPoint({
    required this.id,
    this.shipmentId,
    required this.courierId,
    required this.latitude,
    required this.longitude,
    this.speedMps,
    this.heading,
    this.accuracyM,
    this.recordedAt,
  });

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        latitude,
        longitude,
        speedMps,
        heading,
        accuracyM,
        recordedAt,
      ];
}

