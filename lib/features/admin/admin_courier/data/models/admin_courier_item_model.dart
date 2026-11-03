import '../../domain/entities/admin_courier_item.dart';

class AdminCourierLastLocationModel extends AdminCourierLastLocation {
  const AdminCourierLastLocationModel({
    required super.id,
    required super.shipmentId,
    super.nomorResi,
    required super.courierId,
    required super.latitude,
    required super.longitude,
    super.speedMps,
    super.heading,
    super.accuracyM,
    required super.recordedAt,
  });

  factory AdminCourierLastLocationModel.fromMap(
    Map<String, dynamic> map, {
    String? nomorResi,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final shipmentId = int.tryParse(map['shipment_id']?.toString() ?? '0') ?? 0;
    final courierId = int.tryParse(map['courier_id']?.toString() ?? '0') ?? 0;
    final lat = double.tryParse(map['latitude']?.toString() ?? '0') ?? 0.0;
    final lng = double.tryParse(map['longitude']?.toString() ?? '0') ?? 0.0;
    final speed = double.tryParse(map['speed_mps']?.toString() ?? '');
    final heading = double.tryParse(map['heading']?.toString() ?? '');
    final accuracy = double.tryParse(map['accuracy_m']?.toString() ?? '');
    final recordedStr =
        map['recorded_at']?.toString() ?? map['created_at']?.toString() ?? '';
    final recordedAt =
        DateTime.tryParse(recordedStr)?.toLocal() ?? DateTime.now();

    return AdminCourierLastLocationModel(
      id: id,
      shipmentId: shipmentId,
      nomorResi: nomorResi,
      courierId: courierId,
      latitude: lat,
      longitude: lng,
      speedMps: speed,
      heading: heading,
      accuracyM: accuracy,
      recordedAt: recordedAt,
    );
  }
}

class AdminCourierItemModel extends AdminCourierItem {
  const AdminCourierItemModel({
    required super.id,
    required super.employeeCode,
    super.authUserId,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    super.alamatLengkap,
    super.fotoUrl,
    super.idUsersRole = 2,
    required super.isActive,
    required super.createdAt,
    super.updatedAt,
    super.activeTasksCount = 0,
    super.totalHandledCount = 0,
    super.deliveredCount = 0,
    super.failedCount = 0,
    super.lastLocation,
  });

  factory AdminCourierItemModel.fromMap(
    Map<String, dynamic> map, {
    int activeTasksCount = 0,
    int totalHandledCount = 0,
    int deliveredCount = 0,
    int failedCount = 0,
    AdminCourierLastLocation? lastLocation,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final roleId = int.tryParse(map['id_users_role']?.toString() ?? '2') ?? 2;
    final isActive = map['is_active'] == null ||
        map['is_active'] == true ||
        map['is_active'] == 1;
    final createdStr = map['created_at']?.toString() ?? '';
    final updatedStr = map['updated_at']?.toString() ?? '';
    final createdAt =
        DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now();
    final updatedAt = DateTime.tryParse(updatedStr)?.toLocal();

    final authUserId =
        (map['auth_user_id'] ?? map['user_id'])?.toString();

    return AdminCourierItemModel(
      id: id,
      employeeCode: (map['employee_code'] ?? 'KUR-${id.toString().padLeft(3, '0')}').toString(),
      authUserId: authUserId,
      namaLengkap: (map['nama_lengkap'] ?? map['nama'] ?? 'Kurir SatSet').toString(),
      email: (map['email'] ?? '-').toString(),
      noHp: (map['no_hp'] ?? map['telepon'] ?? '-').toString(),
      alamatLengkap: map['alamat_lengkap']?.toString(),
      fotoUrl: map['foto_url']?.toString(),
      idUsersRole: roleId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      activeTasksCount: activeTasksCount,
      totalHandledCount: totalHandledCount,
      deliveredCount: deliveredCount,
      failedCount: failedCount,
      lastLocation: lastLocation,
    );
  }
}

