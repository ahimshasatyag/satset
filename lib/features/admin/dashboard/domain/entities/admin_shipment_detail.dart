import 'package:equatable/equatable.dart';

/// Entity detail pengiriman lengkap beserta kronologi jejak pelacakan untuk dialog admin
class AdminShipmentDetail extends Equatable {
  final int id;
  final String nomorResi;
  final String barcodeValue;
  final String statusKode;
  final String statusNama;
  final String? statusDeskripsi;

  // Layanan
  final String serviceKode;
  final String serviceNama;
  final int? estimasiHariMin;
  final int? estimasiHariMax;

  // Pengirim
  final String pengirimNama;
  final String pengirimNoHp;
  final String pengirimAlamat;
  final String pengirimKota;
  final String? pengirimKodePos;

  // Penerima
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final String? penerimaKodePos;

  // Paket
  final int totalBeratGram;
  final int panjangCm;
  final int lebarCm;
  final int tinggiCm;
  final int totalBarang;
  final num? nilaiBarang;
  final String? catatanPengiriman;

  // Biaya & Pembayaran
  final num biayaPengiriman;
  final num biayaAsuransi;
  final num biayaLayananTambahan;
  final num diskon;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final String? nomorPembayaran;

  // Kurir Penugasan
  final String? courierNama;
  final String? courierNoHp;
  final String? courierCode;

  // Waktu
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  // Kronologi Pelacakan (t_shipment_tracking)
  final List<AdminTrackingHistoryItem> trackingHistory;

  const AdminShipmentDetail({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    required this.statusKode,
    required this.statusNama,
    this.statusDeskripsi,
    required this.serviceKode,
    required this.serviceNama,
    this.estimasiHariMin,
    this.estimasiHariMax,
    required this.pengirimNama,
    required this.pengirimNoHp,
    required this.pengirimAlamat,
    required this.pengirimKota,
    this.pengirimKodePos,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    required this.penerimaKota,
    this.penerimaKodePos,
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
    this.courierNama,
    this.courierNoHp,
    this.courierCode,
    required this.createdAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.trackingHistory,
  });

  @override
  List<Object?> get props => [
        id,
        nomorResi,
        barcodeValue,
        statusKode,
        statusNama,
        trackingHistory,
      ];
}

/// Entity item kronologi jejak pelacakan (t_shipment_tracking)
class AdminTrackingHistoryItem extends Equatable {
  final int id;
  final String statusKode;
  final String statusNama;
  final String lokasiNama;
  final String catatan;
  final String? employeeNama;
  final DateTime createdAt;

  const AdminTrackingHistoryItem({
    required this.id,
    required this.statusKode,
    required this.statusNama,
    required this.lokasiNama,
    required this.catatan,
    this.employeeNama,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        statusKode,
        statusNama,
        lokasiNama,
        catatan,
        employeeNama,
        createdAt,
      ];
}

