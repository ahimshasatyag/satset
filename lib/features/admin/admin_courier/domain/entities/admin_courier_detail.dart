import 'admin_courier_item.dart';

/// Entitas penugasan pengiriman yang sedang atau pernah ditangani kurir
/// berdasarkan t_shipment_assignments, t_shipments, m_service_types, dan m_shipment_statuses
class AdminCourierAssignmentRecord {
  final int assignmentId;
  final int shipmentId;
  final String nomorResi;
  final String barcodeValue;
  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final String serviceKode;
  final String serviceNama;
  final String statusKode;
  final String statusNama;
  final num totalBeratGram;
  final num totalBiaya;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? unassignedAt;
  final String? catatanPenugasan;

  const AdminCourierAssignmentRecord({
    required this.assignmentId,
    required this.shipmentId,
    required this.nomorResi,
    required this.barcodeValue,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    required this.penerimaKota,
    required this.serviceKode,
    required this.serviceNama,
    required this.statusKode,
    required this.statusNama,
    required this.totalBeratGram,
    required this.totalBiaya,
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    this.unassignedAt,
    this.catatanPenugasan,
  });

  bool get isActiveTask {
    if (unassignedAt != null || completedAt != null) return false;
    final code = statusKode.toUpperCase();
    return code != 'DELIVERED' && code != 'CANCELLED' && code != 'RETURNED';
  }
}

/// Entitas riwayat aktivitas kurir dari t_shipment_tracking dan t_shipment_assignments
class AdminCourierActivityLog {
  final int id;
  final int shipmentId;
  final String nomorResi;
  final String statusKode;
  final String statusNama;
  final String? lokasiNama;
  final double? latitude;
  final double? longitude;
  final String? catatan;
  final String? eventSource;
  final DateTime createdAt;

  const AdminCourierActivityLog({
    required this.id,
    required this.shipmentId,
    required this.nomorResi,
    required this.statusKode,
    required this.statusNama,
    this.lokasiNama,
    this.latitude,
    this.longitude,
    this.catatan,
    this.eventSource,
    required this.createdAt,
  });
}

/// Entitas detail lengkap kurir untuk panel/dialog detail Admin Courier Management
class AdminCourierDetail {
  final AdminCourierItem courier;
  final List<AdminCourierAssignmentRecord> assignments;
  final List<AdminCourierActivityLog> activityLogs;

  const AdminCourierDetail({
    required this.courier,
    required this.assignments,
    required this.activityLogs,
  });

  List<AdminCourierAssignmentRecord> get activeAssignments =>
      assignments.where((a) => a.isActiveTask).toList();

  List<AdminCourierAssignmentRecord> get pastAssignments =>
      assignments.where((a) => !a.isActiveTask).toList();
}

