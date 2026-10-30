import 'package:equatable/equatable.dart';

/// Sumber data alamat:
/// - [mUsers]: Alamat utama dari tabel `m_users`
/// - [mAddress]: Alamat lain/tambahan dari tabel `m_address`
enum AddressSourceType {
  mUsers,
  mAddress;

  bool get isUserPrimary => this == AddressSourceType.mUsers;
}

/// Entity bisnis murni yang merepresentasikan alamat pelanggan.
/// Menggabungkan alamat utama dari tabel `m_users` dan alamat lainnya dari `m_address`.
class CustomerAddress extends Equatable {
  final String id;
  final int? rawId;
  final int? userId;
  final String title;
  final String receiverName;
  final String phoneNumber;
  final String? email;
  final String fullAddress;
  final String? provinceCode;
  final String? provinceName;
  final String? regencyCode;
  final String? regencyName;
  final String? districtCode;
  final String? districtName;
  final String? villageCode;
  final String? villageName;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final int? labelId;
  final String? labelName;
  final bool isPrimary;
  final AddressSourceType sourceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerAddress({
    required this.id,
    this.rawId,
    this.userId,
    required this.title,
    required this.receiverName,
    required this.phoneNumber,
    this.email,
    required this.fullAddress,
    this.provinceCode,
    this.provinceName,
    this.regencyCode,
    this.regencyName,
    this.districtCode,
    this.districtName,
    this.villageCode,
    this.villageName,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.labelId,
    this.labelName,
    this.isPrimary = false,
    this.sourceType = AddressSourceType.mAddress,
    this.createdAt,
    this.updatedAt,
  });

  /// Mengembalikan ringkasan wilayah berjenjang (Kelurahan, Kecamatan, Kab/Kota, Provinsi, Kode Pos)
  String get formattedRegion {
    final parts = <String>[];
    if (villageName != null && villageName!.trim().isNotEmpty) {
      parts.add('Kel. $villageName');
    }
    if (districtName != null && districtName!.trim().isNotEmpty) {
      parts.add('Kec. $districtName');
    }
    if (regencyName != null && regencyName!.trim().isNotEmpty) {
      parts.add(regencyName!);
    }
    if (provinceName != null && provinceName!.trim().isNotEmpty) {
      parts.add(provinceName!);
    }
    if (postalCode != null && postalCode!.trim().isNotEmpty) {
      parts.add(postalCode!);
    }
    return parts.isEmpty ? 'Wilayah belum dilengkapi' : parts.join(', ');
  }

  /// Format alamat lengkap beserta wilayah
  String get completeAddressWithRegion {
    if (fullAddress.trim().isEmpty) return formattedRegion;
    final region = formattedRegion;
    if (region == 'Wilayah belum dilengkapi') return fullAddress;
    return '$fullAddress, $region';
  }

  CustomerAddress copyWith({
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
    return CustomerAddress(
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

  @override
  List<Object?> get props => [
        id,
        rawId,
        userId,
        title,
        receiverName,
        phoneNumber,
        email,
        fullAddress,
        provinceCode,
        provinceName,
        regencyCode,
        regencyName,
        districtCode,
        districtName,
        villageCode,
        villageName,
        postalCode,
        latitude,
        longitude,
        labelId,
        labelName,
        isPrimary,
        sourceType,
        createdAt,
        updatedAt,
      ];
}
/// Master label alamat dari tabel `m_label` di Supabase.
class AddressLabel extends Equatable {
  final int id;
  final String name;

  const AddressLabel({required this.id, required this.name});

  factory AddressLabel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return AddressLabel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      name: (json['nm_label'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name];
}
