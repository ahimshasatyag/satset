import 'package:equatable/equatable.dart';

/// Entity bisnis murni (Plain Dart Object) yang merepresentasikan data pengguna
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? token;
  final String role;
  final String? alamatLengkap;
  final double? latitude;
  final double? longitude;
  final String? googleId;
  final int? idUsersRole;
  final bool? emailVerified;
  final DateTime? emailVerifiedAt;
  final String? idProvinsi;
  final String? idKabkot;
  final String? idKecamatan;
  final String? idKelurahan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.token,
    this.role = 'customer',
    this.idUsersRole,
    this.alamatLengkap,
    this.latitude,
    this.longitude,
    this.googleId,
    this.emailVerified,
    this.emailVerifiedAt,
    this.idProvinsi,
    this.idKabkot,
    this.idKecamatan,
    this.idKelurahan,
    this.createdAt,
    this.updatedAt,
  });

  /// User kosong / guest
  static const empty = User(
    id: '',
    name: '',
    email: '',
    phone: '',
  );

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Helper untuk mengecek apakah user memiliki peran kurir (id_users_role == 2)
  bool get isCourier =>
      idUsersRole == 2 ||
      role.toLowerCase() == 'courier' ||
      role.toLowerCase() == 'kurir';

  /// Helper untuk mengecek apakah user memiliki peran customer (id_users_role == 3)
  bool get isCustomer =>
      idUsersRole == 3 ||
      role.toLowerCase() == 'customer' ||
      (!isCourier);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? token,
    String? role,
    int? idUsersRole,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? googleId,
    bool? emailVerified,
    DateTime? emailVerifiedAt,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
      role: role ?? this.role,
      idUsersRole: idUsersRole ?? this.idUsersRole,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleId: googleId ?? this.googleId,
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      idProvinsi: idProvinsi ?? this.idProvinsi,
      idKabkot: idKabkot ?? this.idKabkot,
      idKecamatan: idKecamatan ?? this.idKecamatan,
      idKelurahan: idKelurahan ?? this.idKelurahan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        photoUrl,
        token,
        role,
        idUsersRole,
        alamatLengkap,
        latitude,
        longitude,
        googleId,
        emailVerified,
        emailVerifiedAt,
        idProvinsi,
        idKabkot,
        idKecamatan,
        idKelurahan,
        createdAt,
        updatedAt,
      ];
}
