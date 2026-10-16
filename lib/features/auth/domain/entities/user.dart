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

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.token,
    this.role = 'customer',
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
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
      role: role ?? this.role,
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
      ];
}
