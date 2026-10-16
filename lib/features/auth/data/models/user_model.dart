import 'dart:convert';
import '../../domain/entities/user.dart';

/// Data Transfer Object (DTO) untuk [User], dilengkapi serialisasi JSON
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.photoUrl,
    super.token,
    super.role = 'customer',
  });

  /// Mengonversi dari Map / JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      token: json['token'] as String?,
      role: json['role'] as String? ?? 'customer',
    );
  }

  /// Mengonversi dari String JSON
  factory UserModel.fromRawJson(String str) =>
      UserModel.fromJson(json.decode(str) as Map<String, dynamic>);

  /// Mengonversi ke Map / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'token': token,
      'role': role,
    };
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
    );
  }
}
