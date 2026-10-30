import '../../domain/entities/address_label.dart';
import '../../domain/entities/customer_address.dart';

/// Model implementasi data layer untuk [CustomerAddress].
/// Mengakomodasi serialisasi dan parsing dari tabel `m_users` dan `m_address`.
class CustomerAddressModel extends CustomerAddress {
  const CustomerAddressModel({
    required super.id,
    super.rawId,
    super.userId,
    required super.title,
    required super.receiverName,
    required super.phoneNumber,
    super.email,
    required super.fullAddress,
    super.provinceCode,
    super.provinceName,
    super.regencyCode,
    super.regencyName,
    super.districtCode,
    super.districtName,
    super.villageCode,
    super.villageName,
    super.postalCode,
    super.latitude,
    super.longitude,
    super.labelId,
    super.labelName,
    super.isPrimary = false,
    super.sourceType = AddressSourceType.mAddress,
    super.createdAt,
    super.updatedAt,
  });

  /// Factory untuk memetakan baris dari tabel `m_users` sebagai Alamat Utama
  factory CustomerAddressModel.fromUsersTable(
    Map<String, dynamic> json, {
    bool? isPrimary,
    String? provinceName,
    String? regencyName,
    String? districtName,
    String? villageName,
    String? postalCode,
  }) {
    final rawUserId = json['id'];
    final userIdInt = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');

    final createdAtStr = json['created_at']?.toString();
    final updatedAtStr = json['updated_at']?.toString();

    final latRaw = json['latitude'];
    final lngRaw = json['longitude'];
    final isUtama = json['is_utama'] == true;

    return CustomerAddressModel(
      id: 'primary_${userIdInt ?? 0}',
      rawId: userIdInt,
      userId: userIdInt,
      title: 'Alamat Utama (Profil Akun)',
      receiverName: (json['nama_lengkap'] ?? 'Pengguna SatSet').toString(),
      phoneNumber: (json['no_hp'] ?? '').toString(),
      email: json['email']?.toString(),
      fullAddress: (json['alamat_lengkap'] ?? '').toString(),
      provinceCode: json['id_provinsi']?.toString(),
      provinceName: provinceName,
      regencyCode: json['id_kabkot']?.toString(),
      regencyName: regencyName,
      districtCode: json['id_kecamatan']?.toString(),
      districtName: districtName,
      villageCode: json['id_kelurahan']?.toString(),
      villageName: villageName,
      postalCode: postalCode,
      latitude: latRaw != null ? double.tryParse(latRaw.toString()) : null,
      longitude: lngRaw != null ? double.tryParse(lngRaw.toString()) : null,
      isPrimary: isPrimary ?? isUtama,
      sourceType: AddressSourceType.mUsers,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  /// Factory untuk memetakan baris dari tabel `m_address` sebagai Alamat Tambahan / Lain
  factory CustomerAddressModel.fromAddressTable(
    Map<String, dynamic> json, {
    bool? isPrimary,
    String? fallbackName,
    String? fallbackPhone,
    String? fallbackEmail,
    String? provinceName,
    String? regencyName,
    String? districtName,
    String? districtCode,
    String? villageName,
  }) {
    final rawId = json['id'];
    final idInt = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final rawUserId = json['id_users'];
    final userIdInt = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');

    final createdAtStr = json['created_at']?.toString();
    final updatedAtStr = json['updated_at']?.toString();

    final rawLabelId = json['id_label'];
    final labelIdInt = rawLabelId is int ? rawLabelId : int.tryParse(rawLabelId?.toString() ?? '');

    String? resolvedLabelName;
    if (json['m_label'] is Map) {
      resolvedLabelName = json['m_label']['nm_label']?.toString();
    } else if (json['nm_label'] != null) {
      resolvedLabelName = json['nm_label']?.toString();
    } else if (labelIdInt != null) {
      resolvedLabelName = AddressLabel.defaultLabels.where((l) => l.id == labelIdInt).firstOrNull?.name;
    }

    final customLabel = json['label']?.toString();
    final effectiveTitle = resolvedLabelName ?? (customLabel != null && customLabel.isNotEmpty ? customLabel : 'Alamat');

    final receiver = json['nama_lengkap']?.toString() ??
        json['penerima_nama']?.toString() ??
        json['nama_penerima']?.toString() ??
        fallbackName ??
        'Penerima Paket';
    final phone = json['no_telp']?.toString() ??
        json['no_hp']?.toString() ??
        json['telepon']?.toString() ??
        fallbackPhone ??
        '-';
    final email = json['email']?.toString() ?? fallbackEmail;

    final rawKelCode = json['id_kelurahan']?.toString();
    String? effectiveDistrictCode = districtCode ?? json['id_kecamatan']?.toString();
    if ((effectiveDistrictCode == null || effectiveDistrictCode.isEmpty) &&
        rawKelCode != null &&
        rawKelCode.contains('.')) {
      final lastDot = rawKelCode.lastIndexOf('.');
      if (lastDot > 0) {
        effectiveDistrictCode = rawKelCode.substring(0, lastDot);
      }
    }

    final isUtama = json['is_utama'] == true;

    return CustomerAddressModel(
      id: 'addr_${idInt ?? DateTime.now().millisecondsSinceEpoch}',
      rawId: idInt,
      userId: userIdInt,
      title: effectiveTitle,
      receiverName: receiver,
      phoneNumber: phone,
      email: email,
      fullAddress: (json['alamat_lengkap'] ?? '').toString(),
      provinceCode: json['id_provinsi']?.toString(),
      provinceName: provinceName,
      regencyCode: json['id_kabkot']?.toString(),
      regencyName: regencyName,
      districtCode: effectiveDistrictCode,
      districtName: districtName,
      villageCode: rawKelCode,
      villageName: villageName,
      postalCode: json['kode_pos']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      labelId: labelIdInt,
      labelName: resolvedLabelName,
      isPrimary: isPrimary ?? isUtama,
      sourceType: AddressSourceType.mAddress,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  /// Konversi data entity/model ke map JSON untuk tabel `m_address`
  Map<String, dynamic> toAddressTableJson() {
    return {
      if (rawId != null && rawId! > 0) 'id': rawId,
      'id_users': userId,
      'alamat_lengkap': fullAddress,
      if (provinceCode != null && provinceCode!.isNotEmpty)
        'id_provinsi': provinceCode,
      if (regencyCode != null && regencyCode!.isNotEmpty)
        'id_kabkot': regencyCode,
      if (villageCode != null && villageCode!.isNotEmpty)
        'id_kelurahan': villageCode,
      if (postalCode != null && postalCode!.isNotEmpty)
        'kode_pos': postalCode,
      'nama_lengkap': receiverName,
      'no_telp': phoneNumber,
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (labelId != null) 'id_label': labelId,
      'is_utama': isPrimary,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Konversi data entity/model ke map JSON untuk pembaruan profil `m_users`
  Map<String, dynamic> toUsersTableUpdateJson() {
    return {
      'alamat_lengkap': fullAddress,
      if (provinceCode != null && provinceCode!.isNotEmpty)
        'id_provinsi': provinceCode,
      if (regencyCode != null && regencyCode!.isNotEmpty)
        'id_kabkot': regencyCode,
      if (districtCode != null && districtCode!.isNotEmpty)
        'id_kecamatan': districtCode,
      if (villageCode != null && villageCode!.isNotEmpty)
        'id_kelurahan': villageCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_utama': isPrimary,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  CustomerAddressModel copyWith({
    String? id,
    int? rawId,
    int? userId,
    String? title,
    String? receiverName,
    String? phoneNumber,
    String? email,
    String? fullAddress,
    String? provinceCode,
    String? provinceName,
    String? regencyCode,
    String? regencyName,
    String? districtCode,
    String? districtName,
    String? villageCode,
    String? villageName,
    String? postalCode,
    double? latitude,
    double? longitude,
    int? labelId,
    String? labelName,
    bool? isPrimary,
    AddressSourceType? sourceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAddressModel(
      id: id ?? this.id,
      rawId: rawId ?? this.rawId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      receiverName: receiverName ?? this.receiverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fullAddress: fullAddress ?? this.fullAddress,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      regencyCode: regencyCode ?? this.regencyCode,
      regencyName: regencyName ?? this.regencyName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      villageCode: villageCode ?? this.villageCode,
      villageName: villageName ?? this.villageName,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      labelId: labelId ?? this.labelId,
      labelName: labelName ?? this.labelName,
      isPrimary: isPrimary ?? this.isPrimary,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerAddressModel.fromEntity(CustomerAddress entity) {
    if (entity is CustomerAddressModel) return entity;
    return CustomerAddressModel(
      id: entity.id,
      rawId: entity.rawId,
      userId: entity.userId,
      title: entity.title,
      receiverName: entity.receiverName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      fullAddress: entity.fullAddress,
      provinceCode: entity.provinceCode,
      provinceName: entity.provinceName,
      regencyCode: entity.regencyCode,
      regencyName: entity.regencyName,
      districtCode: entity.districtCode,
      districtName: entity.districtName,
      villageCode: entity.villageCode,
      villageName: entity.villageName,
      postalCode: entity.postalCode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      labelId: entity.labelId,
      labelName: entity.labelName,
      isPrimary: entity.isPrimary,
      sourceType: entity.sourceType,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
