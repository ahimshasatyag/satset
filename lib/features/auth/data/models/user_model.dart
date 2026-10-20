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
    super.alamatLengkap,
    super.latitude,
    super.longitude,
    super.googleId,
    super.createdAt,
    super.updatedAt,
  });

  /// Mengonversi dari baris tabel Supabase `m_users`
  factory UserModel.fromDatabase(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['nama_lengkap'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['no_hp'] as String? ?? map['phone'] as String? ?? '',
      alamatLengkap: map['alamat_lengkap'] as String?,
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
      googleId: map['google_id'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      photoUrl: map['photo_url'] as String?,
      token: map['token'] as String?,
      role: map['role'] as String? ?? 'customer',
    );
  }

  /// Mengonversi dari Map / JSON umum
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['nama_lengkap'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['no_hp'] as String? ?? json['phone'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      token: json['token'] as String?,
      role: json['role'] as String? ?? 'customer',
      alamatLengkap: json['alamat_lengkap'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      googleId: json['google_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
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
      'alamat_lengkap': alamatLengkap,
      'latitude': latitude,
      'longitude': longitude,
      'google_id': googleId,
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
      'alamat_lengkap': alamatLengkap,
      'latitude': latitude,
      'longitude': longitude,
      'google_id': googleId,
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
      alamatLengkap: user.alamatLengkap,
      latitude: user.latitude,
      longitude: user.longitude,
      googleId: user.googleId,
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
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? googleId,
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
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleId: googleId ?? this.googleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
