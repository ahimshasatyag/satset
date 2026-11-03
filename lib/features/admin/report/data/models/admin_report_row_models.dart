import 'package:satset/features/admin/utils/admin_status_helper.dart';
import '../../domain/entities/admin_report_models.dart';

class AdminShipmentReportRowModel extends AdminShipmentReportRow {
  const AdminShipmentReportRowModel({
    required super.shipmentId,
    required super.nomorResi,
    super.createdAt,
    required super.customerNama,
    required super.pengirimNama,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaKota,
    required super.serviceKode,
    required super.serviceNama,
    required super.statusKode,
    required super.statusNama,
    super.courierId,
    super.courierNama,
    super.courierCode,
    required super.totalBeratGram,
    required super.biayaPengiriman,
    required super.biayaAsuransi,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    super.trackingEventsCount,
    super.hasDeliveryProof,
    super.deliveredAt,
  });

  factory AdminShipmentReportRowModel.fromRawMaps({
    required Map<String, dynamic> shipmentMap,
    Map<String, dynamic>? statusMap,
    Map<String, dynamic>? serviceMap,
    Map<String, dynamic>? customerMap,
    Map<String, dynamic>? courierMap,
    Map<String, dynamic>? paymentMap,
    int trackingCount = 0,
    bool hasProof = false,
  }) {
    final sId = int.tryParse(shipmentMap['id']?.toString() ?? '') ?? 0;
    final nomorResi =
        shipmentMap['nomor_resi']?.toString() ?? 'RESI-$sId';

    final statusKodeRaw = statusMap?['kode']?.toString() ??
        shipmentMap['status_kode']?.toString() ??
        'PENDING';
    final statusNamaRaw = statusMap?['nama_status']?.toString() ??
        AdminStatusHelper.getStatusLabel(statusKodeRaw);

    final serviceKodeRaw = serviceMap?['kode']?.toString() ?? 'REG';
    final serviceNamaRaw =
        serviceMap?['nama_layanan']?.toString() ?? 'Reguler';

    final customerNama = customerMap?['nama_lengkap']?.toString() ??
        shipmentMap['pengirim_nama']?.toString() ??
        'Pelanggan SatSet';

    final courierId = int.tryParse(courierMap?['id']?.toString() ?? '');
    final courierNama = courierMap?['nama_lengkap']?.toString() ??
        courierMap?['nama']?.toString();
    final courierCode = courierMap?['employee_code']?.toString();

    final metode = (paymentMap?['metode_pembayaran']?.toString() ??
            shipmentMap['metode_pembayaran']?.toString() ??
            'TRANSFER')
        .toUpperCase();
    final statusBayar = (paymentMap?['status_pembayaran']?.toString() ??
            'PENDING')
        .toUpperCase();

    return AdminShipmentReportRowModel(
      shipmentId: sId,
      nomorResi: nomorResi,
      createdAt: shipmentMap['created_at'] != null
          ? DateTime.tryParse(shipmentMap['created_at'].toString())
          : null,
      customerNama: customerNama,
      pengirimNama: shipmentMap['pengirim_nama']?.toString() ?? '-',
      pengirimKota: shipmentMap['pengirim_kota']?.toString() ?? '-',
      penerimaNama: shipmentMap['penerima_nama']?.toString() ?? '-',
      penerimaKota: shipmentMap['penerima_kota']?.toString() ?? '-',
      serviceKode: serviceKodeRaw,
      serviceNama: serviceNamaRaw,
      statusKode: statusKodeRaw.toUpperCase(),
      statusNama: statusNamaRaw,
      courierId: courierId,
      courierNama: courierNama,
      courierCode: courierCode,
      totalBeratGram:
          num.tryParse(shipmentMap['total_berat_gram']?.toString() ?? '') ?? 0,
      biayaPengiriman:
          num.tryParse(shipmentMap['biaya_pengiriman']?.toString() ?? '') ?? 0,
      biayaAsuransi:
          num.tryParse(shipmentMap['biaya_asuransi']?.toString() ?? '') ?? 0,
      totalBiaya:
          num.tryParse(shipmentMap['total_biaya']?.toString() ?? '') ?? 0,
      metodePembayaran: metode,
      statusPembayaran: statusBayar,
      trackingEventsCount: trackingCount,
      hasDeliveryProof: hasProof,
      deliveredAt: shipmentMap['delivered_at'] != null
          ? DateTime.tryParse(shipmentMap['delivered_at'].toString())
          : null,
    );
  }
}

class AdminCourierReportRowModel extends AdminCourierReportRow {
  const AdminCourierReportRowModel({
    required super.courierId,
    required super.employeeCode,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    required super.isActive,
    required super.totalAssigned,
    required super.deliveredCount,
    required super.inProgressCount,
    required super.failedOrReturnedCount,
    super.cancelledCount,
    super.trackingUpdatesCount,
    super.proofUploadedCount,
    super.gpsLocationsCount,
    super.totalCodHandled,
    super.lastAssignmentAt,
    super.lastGpsRecordedAt,
  });
}

class AdminCustomerReportRowModel extends AdminCustomerReportRow {
  const AdminCustomerReportRowModel({
    required super.customerId,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    required super.emailVerified,
    super.registeredAt,
    required super.totalShipments,
    required super.deliveredShipments,
    required super.activeShipments,
    required super.failedOrCancelledShipments,
    super.transferPaymentsCount,
    super.codPaymentsCount,
    required super.totalShippingSpend,
    required super.paidShippingSpend,
    super.lastShipmentAt,
  });
}

class AdminPaymentReportRowModel extends AdminPaymentReportRow {
  const AdminPaymentReportRowModel({
    required super.paymentId,
    required super.shipmentId,
    required super.nomorPembayaran,
    required super.nomorResi,
    required super.customerNama,
    required super.serviceKode,
    required super.serviceNama,
    required super.shipmentStatusKode,
    required super.shipmentStatusNama,
    super.courierNama,
    required super.metodePembayaran,
    required super.statusPembayaran,
    super.provider,
    super.providerReference,
    required super.totalBiayaShipment,
    required super.jumlahBayar,
    super.createdAt,
    super.paidAt,
    super.expiredAt,
  });
}
