import 'dart:convert';
import '../../domain/entities/user.dart';

/// Data Transfer Object (DTO) untuk [User], dilengkapi serialisasi JSON & Supabase m_users
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.photoUrl,
    super.token,
    super.role = 'customer',
    super.idUsersRole,
    super.alamatLengkap,
    super.latitude,
    super.longitude,
    super.googleId,
    super.emailVerified,
    super.emailVerifiedAt,
    super.idProvinsi,
    super.idKabkot,
    super.idKecamatan,
    super.idKelurahan,
    super.createdAt,
    super.updatedAt,
  });

  /// Mengonversi dari baris tabel Supabase `m_users` atau `m_employee`
  factory UserModel.fromDatabase(Map<String, dynamic> map) {
    int? parsedRoleId;
    if (map['id_users_role'] != null) {
      parsedRoleId = int.tryParse(map['id_users_role'].toString());
    } else if (map['role_id'] != null) {
      parsedRoleId = int.tryParse(map['role_id'].toString());
    } else {
      final roleStr = (map['role'] as String?)?.toLowerCase();
      if (roleStr == 'courier' || roleStr == 'kurir') {
        parsedRoleId = 2;
      } else if (roleStr == 'customer') {
        parsedRoleId = 3;
      }
    }

    String role = map['role'] as String? ?? '';
    if (role.isEmpty) {
      role = (parsedRoleId == 2) ? 'courier' : 'customer';
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['nama_lengkap'] as String? ??
          map['nama'] as String? ??
          map['name'] as String? ??
          '',
      email: map['email'] as String? ?? '',
      phone: map['no_hp'] as String? ??
          map['telepon'] as String? ??
          map['phone'] as String? ??
          '',
      alamatLengkap: map['alamat_lengkap'] as String?,
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      googleId: map['google_id'] as String?,
      emailVerified: map['email_verified'] == true ||
          map['email_verified'] == 1 ||
          map['email_verified']?.toString().toLowerCase() == 'true',
      emailVerifiedAt: map['email_verified_at'] != null
          ? DateTime.tryParse(map['email_verified_at'].toString())
          : null,
      idProvinsi: map['id_provinsi'] as String?,
      idKabkot: map['id_kabkot'] as String?,
      idKecamatan: map['id_kecamatan'] as String?,
      idKelurahan: map['id_kelurahan'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      photoUrl: map['photo_url'] as String?,
      token: map['token'] as String?,
      role: role,
      idUsersRole: parsedRoleId,
    );
  }

  /// Mengonversi dari Map / JSON umum
  factory UserModel.fromJson(Map<String, dynamic> json) {
    int? parsedRoleId;
    if (json['id_users_role'] != null) {
      parsedRoleId = int.tryParse(json['id_users_role'].toString());
    } else if (json['idUsersRole'] != null) {
      parsedRoleId = int.tryParse(json['idUsersRole'].toString());
    } else if (json['role_id'] != null) {
      parsedRoleId = int.tryParse(json['role_id'].toString());
    } else {
      final roleStr = (json['role'] as String?)?.toLowerCase();
      if (roleStr == 'courier' || roleStr == 'kurir') {
        parsedRoleId = 2;
      } else if (roleStr == 'customer') {
        parsedRoleId = 3;
      }
    }

    String role = json['role'] as String? ?? '';
    if (role.isEmpty) {
      role = (parsedRoleId == 2) ? 'courier' : 'customer';
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['nama_lengkap'] as String? ??
          json['nama'] as String? ??
          json['name'] as String? ??
          '',
      email: json['email'] as String? ?? '',
      phone: json['no_hp'] as String? ??
          json['telepon'] as String? ??
          json['phone'] as String? ??
          '',
      photoUrl: json['photo_url'] as String?,
      token: json['token'] as String?,
      role: role,
      idUsersRole: parsedRoleId,
      alamatLengkap: json['alamat_lengkap'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      googleId: json['google_id'] as String?,
      emailVerified: json['email_verified'] == true ||
          json['email_verified'] == 1 ||
          json['email_verified']?.toString().toLowerCase() == 'true',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      idProvinsi: json['id_provinsi'] as String?,
      idKabkot: json['id_kabkot'] as String?,
      idKecamatan: json['id_kecamatan'] as String?,
      idKelurahan: json['id_kelurahan'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Mengonversi dari String JSON
  factory UserModel.fromRawJson(String str) =>
      UserModel.fromJson(json.decode(str) as Map<String, dynamic>);

  /// Mengonversi ke Map untuk penyimpanan lokal
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'token': token,
      'role': role,
      'id_users_role': idUsersRole,
      'alamat_lengkap': alamatLengkap,
      'latitude': latitude,
      'longitude': longitude,
      'google_id': googleId,
      'email_verified': emailVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'id_provinsi': idProvinsi,
      'id_kabkot': idKabkot,
      'id_kecamatan': idKecamatan,
      'id_kelurahan': idKelurahan,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Mengonversi ke Map kolom tabel PostgreSQL `m_users`
  Map<String, dynamic> toDatabaseInsert({String? hashedPassword}) {
    final map = <String, dynamic>{
      'nama_lengkap': name,
      'email': email.trim().toLowerCase(),
      'no_hp': phone.trim(),
      'role': role,
      'id_users_role': idUsersRole,
      'alamat_lengkap': alamatLengkap,
      'latitude': latitude,
      'longitude': longitude,
      'google_id': googleId,
      'email_verified': emailVerified ?? false,
      if (emailVerifiedAt != null)
        'email_verified_at': emailVerifiedAt!.toIso8601String(),
      if (idProvinsi != null && idProvinsi!.isNotEmpty)
        'id_provinsi': idProvinsi,
      if (idKabkot != null && idKabkot!.isNotEmpty)
        'id_kabkot': idKabkot,
      if (idKecamatan != null && idKecamatan!.isNotEmpty)
        'id_kecamatan': idKecamatan,
      if (idKelurahan != null && idKelurahan!.isNotEmpty)
        'id_kelurahan': idKelurahan,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (hashedPassword != null) {
      map['password'] = hashedPassword;
    }
    return map;
  }

  /// Mengonversi ke String JSON
  String toRawJson() => json.encode(toJson());

  /// Membuat UserModel dari entity User
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photoUrl,
      token: user.token,
      role: user.role,
      idUsersRole: user.idUsersRole,
      alamatLengkap: user.alamatLengkap,
      latitude: user.latitude,
      longitude: user.longitude,
      googleId: user.googleId,
      emailVerified: user.emailVerified,
      emailVerifiedAt: user.emailVerifiedAt,
      idProvinsi: user.idProvinsi,
      idKabkot: user.idKabkot,
      idKecamatan: user.idKecamatan,
      idKelurahan: user.idKelurahan,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
}
