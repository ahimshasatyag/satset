import '../../domain/entities/admin_customer_detail.dart';
import '../../domain/entities/admin_customer_item.dart';

class AdminCustomerAddressRecordModel extends AdminCustomerAddressRecord {
  const AdminCustomerAddressRecordModel({
    required super.id,
    required super.idUsers,
    super.namaPenerima,
    super.noHp,
    super.email,
    super.labelNama,
    required super.alamatLengkap,
    super.idProvinsi,
    super.namaProvinsi,
    super.idKabkot,
    super.namaKabkot,
    super.idKecamatan,
    super.namaKecamatan,
    super.idKelurahan,
    super.namaKelurahan,
    super.kodePos,
    super.latitude,
    super.longitude,
    super.isUtama = false,
    required super.createdAt,
  });

  factory AdminCustomerAddressRecordModel.fromMap(
    Map<String, dynamic> map, {
    String? namaProvinsi,
    String? namaKabkot,
    String? namaKecamatan,
    String? namaKelurahan,
    String? labelNamaOverride,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final idUsers = int.tryParse(
          (map['id_users'] ?? map['user_id'])?.toString() ?? '0',
        ) ??
        0;

    final labelObj = map['m_label'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_label'] as Map)
        : null;
    final provObj = map['m_provinsi'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_provinsi'] as Map)
        : null;
    final kabObj = map['m_kabkot'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_kabkot'] as Map)
        : null;
    final kecObj = map['m_kecamatan'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_kecamatan'] as Map)
        : null;
    final kelObj = map['m_kelurahan'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_kelurahan'] as Map)
        : null;

    final createdStr = map['created_at']?.toString() ?? '';

    return AdminCustomerAddressRecordModel(
      id: id,
      idUsers: idUsers,
      namaPenerima:
          (map['nama_penerima'] ?? map['nama_lengkap'] ?? map['penerima_nama'])
              ?.toString(),
      noHp: (map['no_hp'] ?? map['telepon'])?.toString(),
      email: map['email']?.toString(),
      labelNama: labelNamaOverride ??
          labelObj?['nm_label']?.toString() ??
          map['nm_label']?.toString() ??
          map['label']?.toString(),
      alamatLengkap: (map['alamat_lengkap'] ?? '-').toString(),
      idProvinsi: map['id_provinsi']?.toString(),
      namaProvinsi: namaProvinsi ?? provObj?['nama_provinsi']?.toString(),
      idKabkot: map['id_kabkot']?.toString(),
      namaKabkot: namaKabkot ?? kabObj?['nama_kabkot']?.toString(),
      idKecamatan: map['id_kecamatan']?.toString(),
      namaKecamatan: namaKecamatan ?? kecObj?['nama_kecamatan']?.toString(),
      idKelurahan: map['id_kelurahan']?.toString(),
      namaKelurahan: namaKelurahan ?? kelObj?['nama_kelurahan']?.toString(),
      kodePos: (map['kode_pos'] ?? kelObj?['kodepos'])?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      isUtama: map['is_utama'] == true || map['is_utama'] == 1,
      createdAt:
          DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now(),
    );
  }
}

class AdminCustomerShipmentTrackingStepModel
    extends AdminCustomerShipmentTrackingStep {
  const AdminCustomerShipmentTrackingStepModel({
    required super.id,
    required super.statusKode,
    required super.statusNama,
    super.lokasiNama,
    super.catatan,
    required super.createdAt,
  });

  factory AdminCustomerShipmentTrackingStepModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final statusObj = map['m_shipment_statuses'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_shipment_statuses'] as Map)
        : <String, dynamic>{};
    final createdStr = map['created_at']?.toString() ?? '';

    return AdminCustomerShipmentTrackingStepModel(
      id: id,
      statusKode: (statusObj['kode'] ?? 'PENDING').toString(),
      statusNama: (statusObj['nama_status'] ?? 'Status Diperbarui').toString(),
      lokasiNama: map['lokasi_nama']?.toString(),
      catatan: map['catatan']?.toString(),
      createdAt: DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now(),
    );
  }
}

class AdminCustomerShipmentRecordModel extends AdminCustomerShipmentRecord {
  const AdminCustomerShipmentRecordModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    required super.pengirimNama,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    required super.penerimaKota,
    required super.serviceKode,
    required super.serviceNama,
    required super.statusKode,
    required super.statusNama,
    required super.totalBeratGram,
    required super.biayaPengiriman,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    required super.createdAt,
    super.trackingSteps = const [],
  });

  factory AdminCustomerShipmentRecordModel.fromMap(
    Map<String, dynamic> map, {
    List<AdminCustomerShipmentTrackingStep> trackingSteps = const [],
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final statusObj = map['m_shipment_statuses'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_shipment_statuses'] as Map)
        : <String, dynamic>{};
    final serviceObj = map['m_service_types'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_service_types'] as Map)
        : <String, dynamic>{};

    String paymentStatus = 'PENDING';
    final rawPayments = map['t_shipment_payments'];
    if (rawPayments is List && rawPayments.isNotEmpty) {
      final firstPay = rawPayments.first;
      if (firstPay is Map) {
        paymentStatus =
            (firstPay['status_pembayaran'] ?? 'PENDING').toString();
      }
    } else if (rawPayments is Map) {
      paymentStatus =
          (rawPayments['status_pembayaran'] ?? 'PENDING').toString();
    }

    final createdStr = map['created_at']?.toString() ?? '';

    return AdminCustomerShipmentRecordModel(
      id: id,
      nomorResi: (map['nomor_resi'] ?? 'RESI-$id').toString(),
      barcodeValue:
          (map['barcode_value'] ?? map['nomor_resi'] ?? '-').toString(),
      pengirimNama: (map['pengirim_nama'] ?? '-').toString(),
      penerimaNama: (map['penerima_nama'] ?? '-').toString(),
      penerimaNoHp: (map['penerima_no_hp'] ?? '-').toString(),
      penerimaAlamat: (map['penerima_alamat'] ?? '-').toString(),
      penerimaKota: (map['penerima_kota'] ?? '-').toString(),
      serviceKode: (serviceObj['kode'] ?? 'REG').toString(),
      serviceNama: (serviceObj['nama_layanan'] ?? 'Reguler').toString(),
      statusKode: (statusObj['kode'] ?? 'PENDING').toString(),
      statusNama: (statusObj['nama_status'] ?? 'Menunggu').toString(),
      totalBeratGram:
          num.tryParse(map['total_berat_gram']?.toString() ?? '0') ?? 0,
      biayaPengiriman:
          num.tryParse(map['biaya_pengiriman']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(map['total_biaya']?.toString() ?? '0') ?? 0,
      metodePembayaran: (map['metode_pembayaran'] ?? 'TRANSFER').toString(),
      statusPembayaran: paymentStatus,
      createdAt:
          DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now(),
      trackingSteps: trackingSteps,
    );
  }
}

class AdminCustomerDetailModel extends AdminCustomerDetail {
  const AdminCustomerDetailModel({
    required super.customer,
    required super.additionalAddresses,
    required super.shipments,
  });

  factory AdminCustomerDetailModel.create({
    required AdminCustomerItem customer,
    required List<AdminCustomerAddressRecord> additionalAddresses,
    required List<AdminCustomerShipmentRecord> shipments,
  }) {
    return AdminCustomerDetailModel(
      customer: customer,
      additionalAddresses: additionalAddresses,
      shipments: shipments,
    );
  }
}

