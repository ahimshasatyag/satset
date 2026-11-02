import '../../domain/entities/admin_shipment_detail.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class AdminShipmentDetailModel extends AdminShipmentDetail {
  const AdminShipmentDetailModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    required super.statusKode,
    required super.statusNama,
    super.statusDeskripsi,
    required super.serviceKode,
    required super.serviceNama,
    super.estimasiHariMin,
    super.estimasiHariMax,
    required super.pengirimNama,
    required super.pengirimNoHp,
    required super.pengirimAlamat,
    required super.pengirimKota,
    super.pengirimKodePos,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    required super.penerimaKota,
    super.penerimaKodePos,
    required super.totalBeratGram,
    required super.panjangCm,
    required super.lebarCm,
    required super.tinggiCm,
    required super.totalBarang,
    super.nilaiBarang,
    super.catatanPengiriman,
    required super.biayaPengiriman,
    required super.biayaAsuransi,
    required super.biayaLayananTambahan,
    required super.diskon,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    super.nomorPembayaran,
    super.courierNama,
    super.courierNoHp,
    super.courierCode,
    required super.createdAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.cancelledAt,
    required super.trackingHistory,
  });

  factory AdminShipmentDetailModel.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? courierMap,
    List<Map<String, dynamic>> trackingList = const [],
  }) {
    final status = map['m_shipment_statuses'] is Map<String, dynamic>
        ? map['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};

    final service = map['m_service_types'] is Map<String, dynamic>
        ? map['m_service_types'] as Map<String, dynamic>
        : <String, dynamic>{};

    final payment = map['t_shipment_payments'] is List && (map['t_shipment_payments'] as List).isNotEmpty
        ? (map['t_shipment_payments'] as List).first as Map<String, dynamic>
        : map['t_shipment_payments'] is Map<String, dynamic>
            ? map['t_shipment_payments'] as Map<String, dynamic>
            : <String, dynamic>{};

    final employee = courierMap ??
        (map['courier'] is Map<String, dynamic>
            ? map['courier'] as Map<String, dynamic>
            : <String, dynamic>{});

    final statusCode = (status['kode'] ?? map['status_kode'] ?? 'PENDING').toString().toUpperCase();
    final statusName = status['nama_status'] ?? status['label'] ?? AdminStatusHelper.getStatusLabel(statusCode);

    final history = trackingList.map((t) {
      final tStatus = t['m_shipment_statuses'] is Map<String, dynamic>
          ? t['m_shipment_statuses'] as Map<String, dynamic>
          : <String, dynamic>{};
      final tEmp = t['m_employee'] is Map<String, dynamic>
          ? t['m_employee'] as Map<String, dynamic>
          : <String, dynamic>{};
      final tCode = (tStatus['kode'] ?? t['status_kode'] ?? 'UPDATE').toString().toUpperCase();

      return AdminTrackingHistoryItem(
        id: int.tryParse(t['id']?.toString() ?? '0') ?? 0,
        statusKode: tCode,
        statusNama: tStatus['nama_status'] ?? AdminStatusHelper.getStatusLabel(tCode),
        lokasiNama: t['lokasi_nama']?.toString() ?? 'Pusat Distribusi SatSet',
        catatan: t['catatan']?.toString() ?? '-',
        employeeNama: tEmp['nama_lengkap']?.toString() ?? tEmp['nama']?.toString(),
        createdAt: DateTime.tryParse(t['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();

    return AdminShipmentDetailModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      nomorResi: map['nomor_resi']?.toString() ?? 'SATSET-${map['id']}',
      barcodeValue: map['barcode_value']?.toString() ?? map['nomor_resi']?.toString() ?? '',
      statusKode: statusCode,
      statusNama: statusName.toString(),
      statusDeskripsi: status['deskripsi']?.toString(),
      serviceKode: service['kode']?.toString() ?? 'REG',
      serviceNama: service['nama_layanan']?.toString() ?? 'Reguler',
      estimasiHariMin: int.tryParse(service['estimasi_hari_min']?.toString() ?? ''),
      estimasiHariMax: int.tryParse(service['estimasi_hari_max']?.toString() ?? ''),
      pengirimNama: map['pengirim_nama']?.toString() ?? '-',
      pengirimNoHp: map['pengirim_no_hp']?.toString() ?? '-',
      pengirimAlamat: map['pengirim_alamat']?.toString() ?? '-',
      pengirimKota: map['pengirim_kota']?.toString() ?? '-',
      pengirimKodePos: map['pengirim_kode_pos']?.toString(),
      penerimaNama: map['penerima_nama']?.toString() ?? '-',
      penerimaNoHp: map['penerima_no_hp']?.toString() ?? '-',
      penerimaAlamat: map['penerima_alamat']?.toString() ?? '-',
      penerimaKota: map['penerima_kota']?.toString() ?? '-',
      penerimaKodePos: map['penerima_kode_pos']?.toString(),
      totalBeratGram: int.tryParse(map['total_berat_gram']?.toString() ?? '0') ?? 1000,
      panjangCm: int.tryParse(map['panjang_cm']?.toString() ?? '0') ?? 10,
      lebarCm: int.tryParse(map['lebar_cm']?.toString() ?? '0') ?? 10,
      tinggiCm: int.tryParse(map['tinggi_cm']?.toString() ?? '0') ?? 10,
      totalBarang: int.tryParse(map['total_barang']?.toString() ?? '1') ?? 1,
      nilaiBarang: num.tryParse(map['nilai_barang']?.toString() ?? ''),
      catatanPengiriman: map['catatan_pengiriman']?.toString(),
      biayaPengiriman: num.tryParse(map['biaya_pengiriman']?.toString() ?? '0') ?? 0,
      biayaAsuransi: num.tryParse(map['biaya_asuransi']?.toString() ?? '0') ?? 0,
      biayaLayananTambahan: num.tryParse(map['biaya_layanan_tambahan']?.toString() ?? '0') ?? 0,
      diskon: num.tryParse(map['diskon']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(map['total_biaya']?.toString() ?? '0') ?? 0,
      metodePembayaran: payment['metode_pembayaran']?.toString() ?? map['metode_pembayaran']?.toString() ?? 'Tunai',
      statusPembayaran: payment['status_pembayaran']?.toString() ?? 'PAID',
      nomorPembayaran: payment['nomor_pembayaran']?.toString(),
      courierNama: employee['nama_lengkap']?.toString() ?? employee['nama']?.toString(),
      courierNoHp: employee['no_hp']?.toString() ?? employee['telepon']?.toString(),
      courierCode: employee['employee_code']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      pickedUpAt: DateTime.tryParse(map['picked_up_at']?.toString() ?? ''),
      deliveredAt: DateTime.tryParse(map['delivered_at']?.toString() ?? ''),
      cancelledAt: DateTime.tryParse(map['cancelled_at']?.toString() ?? ''),
      trackingHistory: history,
    );
  }
}

