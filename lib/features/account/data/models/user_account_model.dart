import '../../domain/entities/user_account.dart';

/// Model untuk serialisasi alamat tersimpan pelanggan
class UserAddressModel extends UserAddress {
  const UserAddressModel({
    required super.id,
    required super.label,
    required super.receiverName,
    required super.phone,
    super.provinceCode,
    super.provinceName,
    super.regencyCode,
    super.regencyName,
    super.districtCode,
    super.districtName,
    super.villageCode,
    super.villageName,
    super.postalCode,
    required super.fullAddress,
    super.latitude,
    super.longitude,
    super.isPrimary,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Rumah',
      receiverName: json['receiverName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      provinceCode: json['provinceCode'] as String?,
      provinceName: json['provinceName'] as String?,
      regencyCode: json['regencyCode'] as String?,
      regencyName: json['regencyName'] as String?,
      districtCode: json['districtCode'] as String?,
      districtName: json['districtName'] as String?,
      villageCode: json['villageCode'] as String?,
      villageName: json['villageName'] as String?,
      postalCode: json['postalCode'] as String?,
      fullAddress: json['fullAddress'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  factory UserAddressModel.fromEntity(UserAddress entity) {
    return UserAddressModel(
      id: entity.id,
      label: entity.label,
      receiverName: entity.receiverName,
      phone: entity.phone,
      provinceCode: entity.provinceCode,
      provinceName: entity.provinceName,
      regencyCode: entity.regencyCode,
      regencyName: entity.regencyName,
      districtCode: entity.districtCode,
      districtName: entity.districtName,
      villageCode: entity.villageCode,
      villageName: entity.villageName,
      postalCode: entity.postalCode,
      fullAddress: entity.fullAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isPrimary: entity.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'receiverName': receiverName,
      'phone': phone,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'regencyCode': regencyCode,
      'regencyName': regencyName,
      'districtCode': districtCode,
      'districtName': districtName,
      'villageCode': villageCode,
      'villageName': villageName,
      'postalCode': postalCode,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'isPrimary': isPrimary,
    };
  }
}

/// Model untuk serialisasi profil dan akun pelanggan
class UserAccountModel extends UserAccount {
  const UserAccountModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.avatarUrl,
    super.fullAddress,
    super.latitude,
    super.longitude,
    super.isEmailVerified = false,
    super.shipmentCount = 0,
    super.isNotificationsEnabled = true,
    super.addresses = const [],
    super.membershipTier = 'SatSet Priority Member',
    super.satsetPayBalance = 450000,
    super.savedAddressesCount = 3,
    super.insuranceClaimsCount = 0,
  });

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'] as List<dynamic>?;
    final List<UserAddress> addressList = [];
    if (rawAddresses != null) {
      for (final item in rawAddresses) {
        if (item is Map<String, dynamic>) {
          addressList.add(UserAddressModel.fromJson(item));
        }
      }
    }

    return UserAccountModel(
      id: json['id'] as String? ?? 'usr-01',
      name: json['name'] as String? ?? 'Satria Perkasa',
      email: json['email'] as String? ?? 'satria@satset.id',
      phone: json['phone'] as String? ?? '+62 812-3456-7890',
      avatarUrl: json['avatarUrl'] as String?,
      fullAddress: json['fullAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      shipmentCount: json['shipmentCount'] as int? ?? 0,
      membershipTier:
          json['membershipTier'] as String? ?? 'SatSet Priority Member',
      satsetPayBalance: json['satsetPayBalance'] as int? ?? 450000,
      savedAddressesCount: json['savedAddressesCount'] as int? ??
          (addressList.isNotEmpty ? addressList.length : 3),
      insuranceClaimsCount: json['insuranceClaimsCount'] as int? ?? 0,
      isNotificationsEnabled:
          json['isNotificationsEnabled'] as bool? ?? true,
      addresses: addressList,
    );
  }

  factory UserAccountModel.fromDatabase(
    Map<String, dynamic> userRow, {
    bool isEmailVerified = false,
    int shipmentCount = 0,
    List<UserAddress> addresses = const [],
  }) {
    final id = userRow['id']?.toString() ?? '';
    final name = userRow['nama_lengkap'] as String? ?? '';
    final email = userRow['email'] as String? ?? '';
    final phone = userRow['no_hp'] as String? ?? '';
    final fullAddress = userRow['alamat_lengkap'] as String?;
    final lat = (userRow['latitude'] as num?)?.toDouble();
    final lng = (userRow['longitude'] as num?)?.toDouble();

    return UserAccountModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      fullAddress: fullAddress,
      latitude: lat,
      longitude: lng,
      isEmailVerified: isEmailVerified,
      shipmentCount: shipmentCount,
      addresses: addresses,
      savedAddressesCount: addresses.isNotEmpty ? addresses.length : (fullAddress != null ? 1 : 0),
    );
  }

  factory UserAccountModel.fromEntity(UserAccount entity) {
    return UserAccountModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
      fullAddress: entity.fullAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isEmailVerified: entity.isEmailVerified,
      shipmentCount: entity.shipmentCount,
      membershipTier: entity.membershipTier,
      satsetPayBalance: entity.satsetPayBalance,
      savedAddressesCount: entity.savedAddressesCount,
      insuranceClaimsCount: entity.insuranceClaimsCount,
      isNotificationsEnabled: entity.isNotificationsEnabled,
      addresses: entity.addresses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'isEmailVerified': isEmailVerified,
      'shipmentCount': shipmentCount,
      'membershipTier': membershipTier,
      'satsetPayBalance': satsetPayBalance,
      'savedAddressesCount': savedAddressesCount,
      'insuranceClaimsCount': insuranceClaimsCount,
      'isNotificationsEnabled': isNotificationsEnabled,
      'addresses': addresses
          .map((a) => UserAddressModel.fromEntity(a).toJson())
          .toList(),
    };
  }

  Map<String, dynamic> toDatabase() {
    final data = <String, dynamic>{
      'nama_lengkap': name,
      'no_hp': phone,
    };
    if (fullAddress != null) {
      data['alamat_lengkap'] = fullAddress;
    }
    if (latitude != null) {
      data['latitude'] = latitude;
    }
    if (longitude != null) {
      data['longitude'] = longitude;
    }
    return data;
  }
}
