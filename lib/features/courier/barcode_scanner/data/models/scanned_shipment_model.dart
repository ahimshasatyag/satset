import '../../domain/entities/scanned_shipment.dart';

/// Model data paket pengiriman hasil pemindaian barcode kurir
class ScannedShipmentModel extends ScannedShipment {
  const ScannedShipmentModel({
    required super.shipmentId,
    super.assignmentId,
    super.assignedCourierId,
    required super.trackingNumber,
    required super.barcodeValue,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    required super.statusDescription,
    required super.senderName,
    required super.senderPhone,
    required super.senderAddress,
    required super.senderCity,
    super.senderLatitude,
    super.senderLongitude,
    required super.receiverName,
    required super.receiverPhone,
    required super.receiverAddress,
    required super.receiverCity,
    super.receiverLatitude,
    super.receiverLongitude,
    required super.serviceTypeId,
    required super.serviceTypeName,
    required super.serviceTypeCode,
    required super.weightGram,
    super.notes,
    super.paymentMethod,
    super.paymentStatus,
    super.estimatedArrival,
    super.pickedUpAt,
    super.deliveredAt,
    required super.createdAt,
    required super.updatedAt,
    required super.isAssignedToActiveCourier,
  });

  /// Factory untuk memetakan respon basis data Supabase
  factory ScannedShipmentModel.fromDatabase(
    Map<String, dynamic> map, {
    required String activeCourierId,
    Map<String, dynamic>? assignmentData,
  }) {
    // 1. Ekstrak data pengiriman (bisa langsung di root atau di bawah relasi 't_shipments')
    final shipmentMap = (map['t_shipments'] is Map<String, dynamic>)
        ? map['t_shipments'] as Map<String, dynamic>
        : map;

    // 2. Ekstrak data status (relasi m_shipment_statuses)
    final statusMap = (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>)
        ? shipmentMap['m_shipment_statuses'] as Map<String, dynamic>
        : (map['m_shipment_statuses'] is Map<String, dynamic>)
            ? map['m_shipment_statuses'] as Map<String, dynamic>
            : null;

    final statusId = int.tryParse(shipmentMap['status_id']?.toString() ?? '') ??
        int.tryParse(statusMap?['id']?.toString() ?? '') ??
        1;

    final statusCode = (statusMap?['kode']?.toString() ??
            shipmentMap['status_kode']?.toString() ??
            _fallbackStatusCode(statusId))
        .toUpperCase();

    final statusName = statusMap?['nama_status']?.toString() ??
        statusMap?['label']?.toString() ??
        shipmentMap['status_nama']?.toString() ??
        _fallbackStatusName(statusCode);

    final statusDesc = statusMap?['deskripsi']?.toString() ??
        'Status operasional $statusName';

    // 3. Ekstrak data jenis layanan (relasi m_service_types)
    final serviceMap = (shipmentMap['m_service_types'] is Map<String, dynamic>)
        ? shipmentMap['m_service_types'] as Map<String, dynamic>
        : (map['m_service_types'] is Map<String, dynamic>)
            ? map['m_service_types'] as Map<String, dynamic>
            : null;

    final serviceTypeId = int.tryParse(shipmentMap['service_type_id']?.toString() ?? '') ??
        int.tryParse(serviceMap?['id']?.toString() ?? '') ??
        1;

    final serviceTypeCode = serviceMap?['kode']?.toString() ?? 'REG';
    final serviceTypeName = serviceMap?['nama_layanan']?.toString() ??
        serviceMap?['name']?.toString() ??
        'Reguler';

    // 4. Ekstrak data penugasan kurir (t_shipment_assignments)
    final effectiveAssignment = assignmentData ??
        ((map['t_shipment_assignments'] is Map<String, dynamic>)
            ? map['t_shipment_assignments'] as Map<String, dynamic>
            : ((map['t_shipment_assignments'] is List && (map['t_shipment_assignments'] as List).isNotEmpty)
                ? (map['t_shipment_assignments'] as List).first as Map<String, dynamic>
                : (map.containsKey('courier_id') ? map : null)));

    final assignmentId = effectiveAssignment?['id']?.toString();
    final assignedCourier = effectiveAssignment?['courier_id']?.toString() ??
        effectiveAssignment?['employee_id']?.toString();

    // Validasi apakah paket ditugaskan ke kurir aktif
    final isAssigned = _checkIsAssigned(
      activeCourierId: activeCourierId,
      assignedCourierId: assignedCourier,
      hasDirectAssignment: effectiveAssignment != null,
    );

    final resi = shipmentMap['nomor_resi']?.toString() ?? '';
    final barcode = shipmentMap['barcode_value']?.toString() ?? resi;

    // 5. Ekstrak data pembayaran
    final paymentsRaw = shipmentMap['t_shipment_payments'] ?? map['t_shipment_payments'];
    final paymentMap = paymentsRaw is Map<String, dynamic>
        ? paymentsRaw
        : (paymentsRaw is List && paymentsRaw.isNotEmpty)
            ? paymentsRaw.first as Map<String, dynamic>
            : null;
    final paymentStatus = paymentMap?['status_pembayaran']?.toString() ??
        map['payment_status']?.toString() ??
        shipmentMap['payment_status']?.toString() ??
        'PENDING';
    final paymentMethod = shipmentMap['metode_pembayaran']?.toString() ??
        map['metode_pembayaran']?.toString() ??
        'TRANSFER';

    return ScannedShipmentModel(
      shipmentId: shipmentMap['id']?.toString() ?? '',
      assignmentId: assignmentId,
      assignedCourierId: assignedCourier,
      trackingNumber: resi,
      barcodeValue: barcode,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      statusDescription: statusDesc,
      senderName: shipmentMap['pengirim_nama']?.toString() ?? 'Pengirim SatSet',
      senderPhone: shipmentMap['pengirim_no_hp']?.toString() ?? '-',
      senderAddress: shipmentMap['pengirim_alamat']?.toString() ?? 'Alamat Pengirim',
      senderCity: shipmentMap['pengirim_kota']?.toString() ?? 'Indonesia',
      senderLatitude: double.tryParse(shipmentMap['pengirim_latitude']?.toString() ?? ''),
      senderLongitude: double.tryParse(shipmentMap['pengirim_longitude']?.toString() ?? ''),
      receiverName: shipmentMap['penerima_nama']?.toString() ?? 'Penerima SatSet',
      receiverPhone: shipmentMap['penerima_no_hp']?.toString() ?? '-',
      receiverAddress: shipmentMap['penerima_alamat']?.toString() ?? 'Alamat Penerima',
      receiverCity: shipmentMap['penerima_kota']?.toString() ?? 'Indonesia',
      receiverLatitude: double.tryParse(shipmentMap['penerima_latitude']?.toString() ?? ''),
      receiverLongitude: double.tryParse(shipmentMap['penerima_longitude']?.toString() ?? ''),
      serviceTypeId: serviceTypeId,
      serviceTypeName: serviceTypeName,
      serviceTypeCode: serviceTypeCode,
      weightGram: int.tryParse(shipmentMap['total_berat_gram']?.toString() ?? '') ?? 1000,
      notes: shipmentMap['catatan_pengiriman']?.toString(),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      estimatedArrival: DateTime.tryParse(shipmentMap['estimasi_tiba']?.toString() ?? ''),
      pickedUpAt: DateTime.tryParse(shipmentMap['picked_up_at']?.toString() ?? ''),
      deliveredAt: DateTime.tryParse(shipmentMap['delivered_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(shipmentMap['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(shipmentMap['updated_at']?.toString() ?? '') ?? DateTime.now(),
      isAssignedToActiveCourier: isAssigned,
    );
  }

  /// Cek kecocokan penugasan kurir
  static bool _checkIsAssigned({
    required String activeCourierId,
    required String? assignedCourierId,
    required bool hasDirectAssignment,
  }) {
    if (activeCourierId.trim().isEmpty) return true;
    if (assignedCourierId == null || assignedCourierId.trim().isEmpty) {
      // Jika belum ada assignment eksplisit, kurir yang memindai dapat mengambil penugasan
      return true;
    }
    final activeClean = activeCourierId.trim().toLowerCase();
    final assignedClean = assignedCourierId.trim().toLowerCase();
    return activeClean == assignedClean ||
        (int.tryParse(activeClean) != null &&
            int.tryParse(activeClean) == int.tryParse(assignedClean));
  }

  static String _fallbackStatusCode(int statusId) {
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

  static String _fallbackStatusName(String code) {
    switch (code) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'CONFIRMED':
        return 'Pesanan Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Dijadwalkan Pickup';
      case 'PICKED_UP':
        return 'Paket Telah Di-pickup';
      case 'IN_TRANSIT':
        return 'Dalam Pengiriman / Transit';
      case 'AT_SORTING_CENTER':
        return 'Tiba di Sorting Center';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar ke Penerima';
      case 'DELIVERED':
        return 'Paket Berhasil Diterima';
      case 'FAILED_DELIVERY':
        return 'Pengantaran Gagal';
      case 'RETURNED':
        return 'Paket Dikembalikan';
      case 'CANCELLED':
        return 'Pengiriman Dibatalkan';
      default:
        return 'Memproses Paket';
    }
  }
}
