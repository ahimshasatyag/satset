import 'package:satset/features/admin/utils/admin_status_helper.dart';
import '../../domain/entities/admin_report_detail.dart';

class AdminReportTrackingEventModel extends AdminReportTrackingEvent {
  const AdminReportTrackingEventModel({
    required super.id,
    required super.statusKode,
    required super.statusNama,
    super.lokasiNama,
    super.catatan,
    super.employeeNama,
    super.createdAt,
  });

  factory AdminReportTrackingEventModel.fromMap(
    Map<String, dynamic> map, {
    Map<int, Map<String, dynamic>>? statusById,
    Map<int, Map<String, dynamic>>? employeeById,
  }) {
    final sId = int.tryParse(map['status_id']?.toString() ?? '');
    final empId = int.tryParse(map['employee_id']?.toString() ?? '');
    final statusObj = (map['m_shipment_statuses'] is Map)
        ? Map<String, dynamic>.from(map['m_shipment_statuses'] as Map)
        : ((sId != null && statusById != null) ? statusById[sId] : null);
    final empObj = (map['m_employee'] is Map)
        ? Map<String, dynamic>.from(map['m_employee'] as Map)
        : ((empId != null && employeeById != null) ? employeeById[empId] : null);

    final kode = statusObj?['kode']?.toString() ?? 'IN_TRANSIT';
    final nama = statusObj?['nama_status']?.toString() ??
        AdminStatusHelper.getStatusLabel(kode);

    return AdminReportTrackingEventModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      statusKode: kode.toUpperCase(),
      statusNama: nama,
      lokasiNama: map['lokasi_nama']?.toString(),
      catatan: map['catatan']?.toString(),
      employeeNama: empObj?['nama_lengkap']?.toString() ??
          empObj?['nama']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class AdminReportProofItemModel extends AdminReportProofItem {
  const AdminReportProofItemModel({
    required super.id,
    required super.jenisBukti,
    super.filePath,
    super.penerimaNama,
    super.catatan,
    super.latitude,
    super.longitude,
    super.createdAt,
  });

  factory AdminReportProofItemModel.fromMap(Map<String, dynamic> map) {
    return AdminReportProofItemModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      jenisBukti: map['jenis_bukti']?.toString() ?? 'PHOTO',
      filePath: map['file_path']?.toString(),
      penerimaNama: map['penerima_nama']?.toString(),
      catatan: map['catatan']?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class AdminReportLocationLogModel extends AdminReportLocationLog {
  const AdminReportLocationLogModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    super.speedMps,
    super.accuracyM,
    super.recordedAt,
  });

  factory AdminReportLocationLogModel.fromMap(Map<String, dynamic> map) {
    final recordedRaw = map['recorded_at'] ?? map['created_at'];
    return AdminReportLocationLogModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      latitude: double.tryParse(map['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(map['longitude']?.toString() ?? '') ?? 0.0,
      speedMps: double.tryParse(map['speed_mps']?.toString() ?? ''),
      accuracyM: double.tryParse(map['accuracy_m']?.toString() ?? ''),
      recordedAt:
          recordedRaw != null ? DateTime.tryParse(recordedRaw.toString()) : null,
    );
  }
}
