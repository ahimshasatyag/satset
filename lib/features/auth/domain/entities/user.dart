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
    this.alamatLengkap,
    this.latitude,
    this.longitude,
    this.googleId,
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

  User copyWith({
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
    return User(
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

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        photoUrl,
        token,
        role,
        alamatLengkap,
        latitude,
        longitude,
        googleId,
        createdAt,
        updatedAt,
      ];
}
