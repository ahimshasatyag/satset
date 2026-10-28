import 'package:equatable/equatable.dart';

/// Entity alamat pengiriman tersimpan milik pelanggan
class UserAddress extends Equatable {
  final String id;
  final String label; // contoh: 'Rumah', 'Kantor', 'Gudang'
  final String receiverName;
  final String phone;
  final String? provinceCode;
  final String? provinceName;
  final String? regencyCode;
  final String? regencyName;
  final String? districtCode;
  final String? districtName;
  final String? villageCode;
  final String? villageName;
  final String? postalCode;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;

  const UserAddress({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.phone,
    this.provinceCode,
    this.provinceName,
    this.regencyCode,
    this.regencyName,
    this.districtCode,
    this.districtName,
    this.villageCode,
    this.villageName,
    this.postalCode,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
  });

  UserAddress copyWith({
    String? id,
    String? label,
    String? receiverName,
    String? phone,
    String? provinceCode,
    String? provinceName,
    String? regencyCode,
    String? regencyName,
    String? districtCode,
    String? districtName,
    String? villageCode,
    String? villageName,
    String? postalCode,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isPrimary,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      regencyCode: regencyCode ?? this.regencyCode,
      regencyName: regencyName ?? this.regencyName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      villageCode: villageCode ?? this.villageCode,
      villageName: villageName ?? this.villageName,
      postalCode: postalCode ?? this.postalCode,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        receiverName,
        phone,
        provinceCode,
        provinceName,
        regencyCode,
        regencyName,
        districtCode,
        districtName,
        villageCode,
        villageName,
        postalCode,
        fullAddress,
        latitude,
        longitude,
        isPrimary,
      ];
}

/// Entity profil & informasi akun pelanggan SatSet Delivery
class UserAccount extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;
  final bool isEmailVerified;
  final int shipmentCount;
  final bool isNotificationsEnabled;
  final List<UserAddress> addresses;
  final String membershipTier;
  final int satsetPayBalance;
  final int savedAddressesCount;
  final int insuranceClaimsCount;
  final bool isCourier;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.fullAddress,
    this.latitude,
    this.longitude,
    this.isEmailVerified = false,
    this.shipmentCount = 0,
    this.isNotificationsEnabled = true,
    this.addresses = const [],
    this.membershipTier = 'SatSet Priority Member',
    this.satsetPayBalance = 450000,
    this.savedAddressesCount = 3,
    this.insuranceClaimsCount = 0,
    this.isCourier = false,
  });

  /// Helper untuk mengecek apakah akun merupakan akun kurir
  bool get isCourierAccount =>
      isCourier ||
      membershipTier.toLowerCase().contains('kurir') ||
      membershipTier.toLowerCase().contains('courier');

  /// Mengambil alamat utama jika ada
  UserAddress? get primaryAddress {
    if (addresses.isEmpty) return null;
    for (final a in addresses) {
      if (a.isPrimary) return a;
    }
    return addresses.first;
  }

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isEmailVerified,
    int? shipmentCount,
    bool? isNotificationsEnabled,
    List<UserAddress>? addresses,
    String? membershipTier,
    int? satsetPayBalance,
    int? savedAddressesCount,
    int? insuranceClaimsCount,
    bool? isCourier,
  }) {
    final updatedAddresses = addresses ?? this.addresses;
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      shipmentCount: shipmentCount ?? this.shipmentCount,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      addresses: updatedAddresses,
      membershipTier: membershipTier ?? this.membershipTier,
      satsetPayBalance: satsetPayBalance ?? this.satsetPayBalance,
      savedAddressesCount:
          savedAddressesCount ?? updatedAddresses.length,
      insuranceClaimsCount: insuranceClaimsCount ?? this.insuranceClaimsCount,
      isCourier: isCourier ?? this.isCourier,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatarUrl,
        fullAddress,
        latitude,
        longitude,
        isEmailVerified,
        shipmentCount,
        isNotificationsEnabled,
        addresses,
        membershipTier,
        satsetPayBalance,
        savedAddressesCount,
        insuranceClaimsCount,
        isCourier,
      ];
}
