import '../../domain/entities/admin_shipment_table_item.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class AdminShipmentTableModel extends AdminShipmentTableItem {
  const AdminShipmentTableModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    required super.pengirimNama,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaKota,
    required super.serviceKode,
    required super.serviceNama,
    required super.courierNama,
    required super.courierCode,
    required super.statusKode,
    required super.statusNama,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    required super.createdAt,
  });

  factory AdminShipmentTableModel.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? courierMap,
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

    return AdminShipmentTableModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      nomorResi: map['nomor_resi']?.toString() ?? 'SATSET-${map['id']}',
      barcodeValue: map['barcode_value']?.toString() ?? map['nomor_resi']?.toString() ?? '',
      pengirimNama: map['pengirim_nama']?.toString() ?? '-',
      pengirimKota: map['pengirim_kota']?.toString() ?? '-',
      penerimaNama: map['penerima_nama']?.toString() ?? '-',
      penerimaKota: map['penerima_kota']?.toString() ?? '-',
      serviceKode: service['kode']?.toString() ?? 'REG',
      serviceNama: service['nama_layanan']?.toString() ?? 'Reguler',
      courierNama: employee['nama_lengkap']?.toString() ?? employee['nama']?.toString() ?? 'Belum Ditugaskan',
      courierCode: employee['employee_code']?.toString() ?? '-',
      statusKode: statusCode,
      statusNama: statusName.toString(),
      totalBiaya: num.tryParse(map['total_biaya']?.toString() ?? '0') ?? 0,
      metodePembayaran: payment['metode_pembayaran']?.toString() ?? map['metode_pembayaran']?.toString() ?? 'Tunai',
      statusPembayaran: payment['status_pembayaran']?.toString() ?? 'PAID',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

