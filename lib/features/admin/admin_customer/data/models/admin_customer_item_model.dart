import '../../domain/entities/admin_customer_item.dart';

class AdminWilayahOptionModel extends AdminWilayahOption {
  const AdminWilayahOptionModel({
    required super.kode,
    required super.nama,
    super.parentKode,
    super.kodePos,
  });

  factory AdminWilayahOptionModel.fromProvinsiMap(Map<String, dynamic> map) {
    return AdminWilayahOptionModel(
      kode: (map['kode_provinsi'] ?? map['id'] ?? '').toString(),
      nama: (map['nama_provinsi'] ?? '').toString(),
    );
  }

  factory AdminWilayahOptionModel.fromKabkotMap(Map<String, dynamic> map) {
    final jenis = map['jenis']?.toString() ?? '';
    final namaRaw = (map['nama_kabkot'] ?? '').toString();
    final fullNama = jenis.isNotEmpty &&
            !namaRaw.toLowerCase().startsWith(jenis.toLowerCase())
        ? '$jenis $namaRaw'
        : namaRaw;
    return AdminWilayahOptionModel(
      kode: (map['kode_kabkot'] ?? map['id'] ?? '').toString(),
      nama: fullNama,
      parentKode: map['kode_provinsi']?.toString(),
    );
  }

  factory AdminWilayahOptionModel.fromKecamatanMap(Map<String, dynamic> map) {
    return AdminWilayahOptionModel(
      kode: (map['kode_kecamatan'] ?? map['id'] ?? '').toString(),
      nama: (map['nama_kecamatan'] ?? '').toString(),
      parentKode: map['kode_kabkot']?.toString(),
    );
  }

  factory AdminWilayahOptionModel.fromKelurahanMap(Map<String, dynamic> map) {
    return AdminWilayahOptionModel(
      kode: (map['kode_kelurahan'] ?? map['id'] ?? '').toString(),
      nama: (map['nama_kelurahan'] ?? '').toString(),
      parentKode: map['kode_kecamatan']?.toString(),
      kodePos: map['kodepos']?.toString(),
    );
  }
}

class AdminCustomerItemModel extends AdminCustomerItem {
  const AdminCustomerItemModel({
    required super.id,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    super.idUsersRole = 3,
    required super.emailVerified,
    super.emailVerifiedAt,
    super.googleId,
    super.alamatLengkap,
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
    super.isUtama = true,
    required super.createdAt,
    super.updatedAt,
    super.totalShipmentsCount = 0,
    super.deliveredShipmentsCount = 0,
    super.ongoingShipmentsCount = 0,
    super.failedShipmentsCount = 0,
    super.totalTransactionAmount = 0,
  });

  factory AdminCustomerItemModel.fromMap(
    Map<String, dynamic> map, {
    String? namaProvinsi,
    String? namaKabkot,
    String? namaKecamatan,
    String? namaKelurahan,
    String? kodePos,
    int totalShipmentsCount = 0,
    int deliveredShipmentsCount = 0,
    int ongoingShipmentsCount = 0,
    int failedShipmentsCount = 0,
    num totalTransactionAmount = 0,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final roleId = int.tryParse(map['id_users_role']?.toString() ?? '3') ?? 3;
    final verified =
        map['email_verified'] == true || map['email_verified'] == 1;
    final verifiedAtStr = map['email_verified_at']?.toString() ?? '';
    final createdStr = map['created_at']?.toString() ?? '';
    final updatedStr = map['updated_at']?.toString() ?? '';

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

    return AdminCustomerItemModel(
      id: id,
      namaLengkap: (map['nama_lengkap'] ?? 'Pelanggan SatSet').toString(),
      email: (map['email'] ?? '-').toString(),
      noHp: (map['no_hp'] ?? '-').toString(),
      idUsersRole: roleId,
      emailVerified: verified,
      emailVerifiedAt: DateTime.tryParse(verifiedAtStr)?.toLocal(),
      googleId: map['google_id']?.toString(),
      alamatLengkap: map['alamat_lengkap']?.toString(),
      idProvinsi: map['id_provinsi']?.toString(),
      namaProvinsi: namaProvinsi ?? provObj?['nama_provinsi']?.toString(),
      idKabkot: map['id_kabkot']?.toString(),
      namaKabkot: namaKabkot ?? kabObj?['nama_kabkot']?.toString(),
      idKecamatan: map['id_kecamatan']?.toString(),
      namaKecamatan: namaKecamatan ?? kecObj?['nama_kecamatan']?.toString(),
      idKelurahan: map['id_kelurahan']?.toString(),
      namaKelurahan: namaKelurahan ?? kelObj?['nama_kelurahan']?.toString(),
      kodePos: kodePos ??
          kelObj?['kodepos']?.toString() ??
          map['kode_pos']?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      isUtama: map['is_utama'] == null || map['is_utama'] == true,
      createdAt:
          DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedStr)?.toLocal(),
      totalShipmentsCount: totalShipmentsCount,
      deliveredShipmentsCount: deliveredShipmentsCount,
      ongoingShipmentsCount: ongoingShipmentsCount,
      failedShipmentsCount: failedShipmentsCount,
      totalTransactionAmount: totalTransactionAmount,
    );
  }
}

