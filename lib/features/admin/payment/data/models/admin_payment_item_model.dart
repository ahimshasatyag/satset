import 'package:satset/features/admin/utils/admin_status_helper.dart';
import '../../domain/entities/admin_payment_item.dart';

class AdminBankReferenceModel extends AdminBankReference {
  const AdminBankReferenceModel({
    required super.bankId,
    required super.namaPemilik,
    required super.nomorRekening,
    required super.jenisBankId,
    required super.namaJenisBank,
    super.createdAt,
  });

  factory AdminBankReferenceModel.fromMap(
    Map<String, dynamic> bankMap, {
    Map<String, dynamic>? jenisBankMap,
  }) {
    final nestedJenis = bankMap['m_jenis_bank'] is Map<String, dynamic>
        ? bankMap['m_jenis_bank'] as Map<String, dynamic>
        : (jenisBankMap ?? <String, dynamic>{});

    return AdminBankReferenceModel(
      bankId: (bankMap['id'] ?? '').toString(),
      namaPemilik: (bankMap['nm_bank'] ?? '').toString(),
      nomorRekening: (bankMap['nmr_rekening'] ?? '').toString(),
      jenisBankId:
          (bankMap['jenis_bank_id'] ?? nestedJenis['id'] ?? '').toString(),
      namaJenisBank: (nestedJenis['nama_jenis'] ?? '').toString(),
      createdAt: bankMap['created_at'] != null
          ? DateTime.tryParse(bankMap['created_at'].toString())
          : null,
    );
  }
}

class AdminPaymentItemModel extends AdminPaymentItem {
  const AdminPaymentItemModel({
    required super.id,
    required super.shipmentId,
    required super.nomorPembayaran,
    required super.nomorResi,
    required super.barcodeValue,
    super.customerId,
    required super.customerNama,
    required super.customerEmail,
    required super.customerNoHp,
    required super.pengirimNama,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaKota,
    required super.penerimaAlamat,
    super.serviceTypeId,
    required super.serviceKode,
    required super.serviceNama,
    super.shipmentStatusId,
    required super.shipmentStatusKode,
    required super.shipmentStatusNama,
    required super.biayaPengiriman,
    required super.biayaAsuransi,
    required super.biayaLayananTambahan,
    required super.diskon,
    required super.totalBiayaShipment,
    required super.metodePembayaran,
    required super.statusPembayaran,
    required super.jumlahBayar,
    super.provider,
    super.providerReference,
    super.buktiPembayaranPath,
    super.jenisBankId,
    super.namaJenisBank,
    super.namaPemilikRekening,
    super.nomorRekeningBank,
    super.paidAt,
    super.expiredAt,
    super.createdAt,
    super.updatedAt,
  });

  factory AdminPaymentItemModel.fromMap(
    Map<String, dynamic> paymentMap, {
    Map<String, dynamic>? shipmentMap,
    Map<String, dynamic>? customerMap,
    Map<String, dynamic>? statusMap,
    Map<String, dynamic>? serviceMap,
    AdminBankReference? bankRef,
    String? fallbackJenisBankName,
  }) {
    final sMap = shipmentMap ??
        (paymentMap['t_shipments'] is Map<String, dynamic>
            ? paymentMap['t_shipments'] as Map<String, dynamic>
            : <String, dynamic>{});

    final uMap = customerMap ??
        (sMap['m_users'] is Map<String, dynamic>
            ? sMap['m_users'] as Map<String, dynamic>
            : <String, dynamic>{});

    final stMap = statusMap ??
        (sMap['m_shipment_statuses'] is Map<String, dynamic>
            ? sMap['m_shipment_statuses'] as Map<String, dynamic>
            : <String, dynamic>{});

    final svMap = serviceMap ??
        (sMap['m_service_types'] is Map<String, dynamic>
            ? sMap['m_service_types'] as Map<String, dynamic>
            : <String, dynamic>{});

    final paymentId =
        int.tryParse(paymentMap['id']?.toString() ?? '0') ?? 0;
    final shipmentId = int.tryParse(
          (paymentMap['shipment_id'] ?? sMap['id'])?.toString() ?? '0',
        ) ??
        0;

    final nomorResi =
        (sMap['nomor_resi'] ?? 'SST-$shipmentId').toString();
    final barcodeValue =
        (sMap['barcode_value'] ?? nomorResi).toString();

    final pengirimNama =
        (sMap['pengirim_nama'] ?? '-').toString();
    final customerNama =
        (uMap['nama_lengkap'] ?? pengirimNama).toString();
    final customerEmail = (uMap['email'] ?? '-').toString();
    final customerNoHp =
        (uMap['no_hp'] ?? sMap['pengirim_no_hp'] ?? '-').toString();

    final shipmentStatusId = int.tryParse(
      (stMap['id'] ?? sMap['status_id'])?.toString() ?? '',
    );
    final shipmentStatusKode =
        (stMap['kode'] ?? _resolveStatusCode(shipmentStatusId ?? 1))
            .toString()
            .toUpperCase();
    final shipmentStatusNama = (stMap['nama_status'] ??
            AdminStatusHelper.getStatusLabel(shipmentStatusKode))
        .toString();

    final serviceTypeId = int.tryParse(
      (svMap['id'] ?? sMap['service_type_id'])?.toString() ?? '',
    );
    final serviceKode =
        (svMap['kode'] ?? 'REG').toString().toUpperCase();
    final serviceNama =
        (svMap['nama_layanan'] ?? 'Reguler').toString();

    final biayaPengiriman =
        num.tryParse(sMap['biaya_pengiriman']?.toString() ?? '0') ?? 0;
    final biayaAsuransi =
        num.tryParse(sMap['biaya_asuransi']?.toString() ?? '0') ?? 0;
    final biayaLayananTambahan =
        num.tryParse(sMap['biaya_layanan_tambahan']?.toString() ?? '0') ?? 0;
    final diskon = num.tryParse(sMap['diskon']?.toString() ?? '0') ?? 0;
    final totalBiayaShipment =
        num.tryParse(sMap['total_biaya']?.toString() ?? '0') ??
            (biayaPengiriman + biayaAsuransi + biayaLayananTambahan - diskon);

    final metodePembayaran = (paymentMap['metode_pembayaran'] ??
            sMap['metode_pembayaran'] ??
            'TRANSFER')
        .toString()
        .toUpperCase();

    final rawStatus = (paymentMap['status_pembayaran'] ??
            (metodePembayaran == 'COD' ? 'COD' : 'PENDING'))
        .toString()
        .toUpperCase();

    final jumlahBayar =
        num.tryParse(paymentMap['jumlah_bayar']?.toString() ?? '') ??
            totalBiayaShipment;

    final jenisBankId = paymentMap['jenis_bank_id']?.toString();

    return AdminPaymentItemModel(
      id: paymentId,
      shipmentId: shipmentId,
      nomorPembayaran:
          (paymentMap['nomor_pembayaran'] ?? 'PAY-$paymentId').toString(),
      nomorResi: nomorResi,
      barcodeValue: barcodeValue,
      customerId: int.tryParse(
        (sMap['customer_id'] ?? uMap['id'])?.toString() ?? '',
      ),
      customerNama: customerNama,
      customerEmail: customerEmail,
      customerNoHp: customerNoHp,
      pengirimNama: pengirimNama,
      pengirimKota: (sMap['pengirim_kota'] ?? '-').toString(),
      penerimaNama: (sMap['penerima_nama'] ?? '-').toString(),
      penerimaNoHp: (sMap['penerima_no_hp'] ?? '-').toString(),
      penerimaKota: (sMap['penerima_kota'] ?? '-').toString(),
      penerimaAlamat: (sMap['penerima_alamat'] ?? '-').toString(),
      serviceTypeId: serviceTypeId,
      serviceKode: serviceKode,
      serviceNama: serviceNama,
      shipmentStatusId: shipmentStatusId,
      shipmentStatusKode: shipmentStatusKode,
      shipmentStatusNama: shipmentStatusNama,
      biayaPengiriman: biayaPengiriman,
      biayaAsuransi: biayaAsuransi,
      biayaLayananTambahan: biayaLayananTambahan,
      diskon: diskon,
      totalBiayaShipment: totalBiayaShipment,
      metodePembayaran: metodePembayaran,
      statusPembayaran: rawStatus,
      jumlahBayar: jumlahBayar,
      provider: paymentMap['provider']?.toString() ?? bankRef?.namaJenisBank,
      providerReference: paymentMap['provider_reference']?.toString() ??
          bankRef?.nomorRekening,
      buktiPembayaranPath: paymentMap['bukti_pembayaran_path']?.toString(),
      jenisBankId: jenisBankId,
      namaJenisBank: bankRef?.namaJenisBank ?? fallbackJenisBankName,
      namaPemilikRekening: bankRef?.namaPemilik,
      nomorRekeningBank: bankRef?.nomorRekening,
      paidAt: paymentMap['paid_at'] != null
          ? DateTime.tryParse(paymentMap['paid_at'].toString())
          : null,
      expiredAt: paymentMap['expired_at'] != null
          ? DateTime.tryParse(paymentMap['expired_at'].toString())
          : null,
      createdAt: paymentMap['created_at'] != null
          ? DateTime.tryParse(paymentMap['created_at'].toString())
          : (sMap['created_at'] != null
              ? DateTime.tryParse(sMap['created_at'].toString())
              : null),
      updatedAt: paymentMap['updated_at'] != null
          ? DateTime.tryParse(paymentMap['updated_at'].toString())
          : null,
    );
  }

  static String _resolveStatusCode(int statusId) {
    switch (statusId) {
      case 1:
        return 'PENDING';
      case 2:
        return 'CONFIRMED';
      case 3:
        return 'PICKUP_SCHEDULED';
      case 4:
        return 'PICKED_UP';
      case 5:
        return 'IN_TRANSIT';
      case 6:
        return 'AT_SORTING_CENTER';
      case 7:
        return 'OUT_FOR_DELIVERY';
      case 8:
        return 'DELIVERED';
      case 9:
        return 'FAILED_DELIVERY';
      case 10:
        return 'RETURNED';
      case 11:
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }
}

