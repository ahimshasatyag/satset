import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    super.email = '',
    super.phone = '',
    super.avatarUrl = '',
    super.alamatLengkap,
    super.currentCity = 'Jakarta',
    super.currentSubdistrict = 'Pusat',
    super.currentLatitude = -6.2088,
    super.currentLongitude = 106.8456,
    super.hasUnreadCourierUpdates = false,
    super.unreadCount = 0,
  });

  /// Factory untuk konversi dari baris tabel Supabase m_users
  factory UserProfileModel.fromDatabase(Map<String, dynamic> map) {
    final alamat = map['alamat_lengkap'] as String?;
    String city = 'Jakarta';
    String subdistrict = 'Pusat';
    if (alamat != null && alamat.contains(',')) {
      final parts = alamat.split(',');
      if (parts.length >= 2) {
        final last = parts.last.trim();
        final prev = parts[parts.length - 2].trim();
        if (prev.toLowerCase().startsWith('jl') ||
            prev.toLowerCase().startsWith('jalan') ||
            prev.contains('No.')) {
          city = last;
          subdistrict = last.contains(' ') ? last.split(' ').last : 'Pusat';
        } else {
          subdistrict = prev;
          city = last;
        }
      }
    }

    return UserProfileModel(
      id: map['id']?.toString() ?? '',
      name: (map['nama_lengkap'] as String?)?.trim().isNotEmpty == true
          ? (map['nama_lengkap'] as String).trim()
          : (map['name'] as String?)?.trim() ?? 'Pelanggan',
      email: map['email'] as String? ?? '',
      phone: map['no_hp'] as String? ?? map['phone'] as String? ?? '',
      avatarUrl: map['photo_url'] as String? ?? '',
      alamatLengkap: alamat,
      currentCity: city,
      currentSubdistrict: subdistrict,
      currentLatitude:
          double.tryParse(map['latitude']?.toString() ?? '') ?? -6.2088,
      currentLongitude:
          double.tryParse(map['longitude']?.toString() ?? '') ?? 106.8456,
      hasUnreadCourierUpdates: false,
      unreadCount: 0,
    );
  }

  /// Factory dari User domain entity (dari AuthBloc / LoginPage)
  factory UserProfileModel.fromUser(User user) {
    return UserProfileModel(
      id: user.id,
      name: user.name.isNotEmpty ? user.name : 'Pelanggan',
      email: user.email,
      phone: user.phone,
      avatarUrl: user.photoUrl ?? '',
      alamatLengkap: user.alamatLengkap,
      currentCity: 'Jakarta',
      currentSubdistrict: 'Pusat',
      currentLatitude: user.latitude ?? -6.2088,
      currentLongitude: user.longitude ?? 106.8456,
      hasUnreadCourierUpdates: false,
      unreadCount: 0,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Pelanggan',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      alamatLengkap: json['alamatLengkap'] as String?,
      currentCity: json['currentCity'] as String? ?? 'Jakarta',
      currentSubdistrict: json['currentSubdistrict'] as String? ?? 'Pusat',
      currentLatitude:
          (json['currentLatitude'] as num?)?.toDouble() ?? -6.2088,
      currentLongitude:
          (json['currentLongitude'] as num?)?.toDouble() ?? 106.8456,
      hasUnreadCourierUpdates:
          json['hasUnreadCourierUpdates'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'alamatLengkap': alamatLengkap,
      'currentCity': currentCity,
      'currentSubdistrict': currentSubdistrict,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'hasUnreadCourierUpdates': hasUnreadCourierUpdates,
      'unreadCount': unreadCount,
    };
  }
}
