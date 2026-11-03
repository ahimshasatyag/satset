import '../../domain/entities/admin_courier_detail.dart';
import '../../domain/entities/admin_courier_item.dart';

class AdminCourierAssignmentRecordModel extends AdminCourierAssignmentRecord {
  const AdminCourierAssignmentRecordModel({
    required super.assignmentId,
    required super.shipmentId,
    required super.nomorResi,
    required super.barcodeValue,
    required super.pengirimNama,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    required super.penerimaKota,
    required super.serviceKode,
    required super.serviceNama,
    required super.statusKode,
    required super.statusNama,
    required super.totalBeratGram,
    required super.totalBiaya,
    required super.assignedAt,
    super.acceptedAt,
    super.completedAt,
    super.unassignedAt,
    super.catatanPenugasan,
  });

  factory AdminCourierAssignmentRecordModel.fromMap(
    Map<String, dynamic> assignmentMap, {
    Map<String, dynamic>? shipmentMap,
  }) {
    final assignId = int.tryParse(assignmentMap['id']?.toString() ?? '0') ?? 0;
    final sId = int.tryParse(
          (assignmentMap['shipment_id'] ?? shipmentMap?['id'])?.toString() ??
              '0',
        ) ??
        0;

    final ship = shipmentMap ??
        (assignmentMap['t_shipments'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(assignmentMap['t_shipments'] as Map)
            : <String, dynamic>{});

    final statusObj = ship['m_shipment_statuses'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(ship['m_shipment_statuses'] as Map)
        : <String, dynamic>{};
    final serviceObj = ship['m_service_types'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(ship['m_service_types'] as Map)
        : <String, dynamic>{};

    final assignedStr = assignmentMap['assigned_at']?.toString() ??
        assignmentMap['created_at']?.toString() ??
        '';
    final acceptedStr = assignmentMap['accepted_at']?.toString() ?? '';
    final completedStr = assignmentMap['completed_at']?.toString() ??
        ship['delivered_at']?.toString() ??
        '';
    final unassignedStr = assignmentMap['unassigned_at']?.toString() ?? '';

    return AdminCourierAssignmentRecordModel(
      assignmentId: assignId,
      shipmentId: sId,
      nomorResi: (ship['nomor_resi'] ?? 'RESI-$sId').toString(),
      barcodeValue:
          (ship['barcode_value'] ?? ship['nomor_resi'] ?? '-').toString(),
      pengirimNama: (ship['pengirim_nama'] ?? '-').toString(),
      pengirimKota: (ship['pengirim_kota'] ?? '-').toString(),
      penerimaNama: (ship['penerima_nama'] ?? '-').toString(),
      penerimaNoHp: (ship['penerima_no_hp'] ?? '-').toString(),
      penerimaAlamat: (ship['penerima_alamat'] ?? '-').toString(),
      penerimaKota: (ship['penerima_kota'] ?? '-').toString(),
      serviceKode: (serviceObj['kode'] ?? 'REG').toString(),
      serviceNama: (serviceObj['nama_layanan'] ?? 'Reguler').toString(),
      statusKode: (statusObj['kode'] ?? 'PENDING').toString(),
      statusNama: (statusObj['nama_status'] ?? 'Menunggu').toString(),
      totalBeratGram:
          num.tryParse(ship['total_berat_gram']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(ship['total_biaya']?.toString() ?? '0') ?? 0,
      assignedAt:
          DateTime.tryParse(assignedStr)?.toLocal() ?? DateTime.now(),
      acceptedAt: DateTime.tryParse(acceptedStr)?.toLocal(),
      completedAt: DateTime.tryParse(completedStr)?.toLocal(),
      unassignedAt: DateTime.tryParse(unassignedStr)?.toLocal(),
      catatanPenugasan: assignmentMap['catatan']?.toString(),
    );
  }
}

class AdminCourierActivityLogModel extends AdminCourierActivityLog {
  const AdminCourierActivityLogModel({
    required super.id,
    required super.shipmentId,
    required super.nomorResi,
    required super.statusKode,
    required super.statusNama,
    super.lokasiNama,
    super.latitude,
    super.longitude,
    super.catatan,
    super.eventSource,
    required super.createdAt,
  });

  factory AdminCourierActivityLogModel.fromMap(
    Map<String, dynamic> map, {
    String? nomorResiOverride,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final shipmentId = int.tryParse(map['shipment_id']?.toString() ?? '0') ?? 0;

    final statusObj = map['m_shipment_statuses'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['m_shipment_statuses'] as Map)
        : <String, dynamic>{};
    final shipObj = map['t_shipments'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['t_shipments'] as Map)
        : <String, dynamic>{};

    final createdStr = map['created_at']?.toString() ?? '';

    return AdminCourierActivityLogModel(
      id: id,
      shipmentId: shipmentId,
      nomorResi: nomorResiOverride ??
          (shipObj['nomor_resi'] ??
                  map['barcode_value'] ??
                  'RESI-$shipmentId')
              .toString(),
      statusKode: (statusObj['kode'] ?? 'IN_TRANSIT').toString(),
      statusNama:
          (statusObj['nama_status'] ?? 'Pembaruan Status').toString(),
      lokasiNama: map['lokasi_nama']?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      catatan: map['catatan']?.toString(),
      eventSource: map['event_source']?.toString(),
      createdAt: DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now(),
    );
  }
}

class AdminCourierDetailModel extends AdminCourierDetail {
  const AdminCourierDetailModel({
    required super.courier,
    required super.assignments,
    required super.activityLogs,
  });

  factory AdminCourierDetailModel.create({
    required AdminCourierItem courier,
    required List<AdminCourierAssignmentRecord> assignments,
    required List<AdminCourierActivityLog> activityLogs,
  }) {
    return AdminCourierDetailModel(
      courier: courier,
      assignments: assignments,
      activityLogs: activityLogs,
    );
  }
}

