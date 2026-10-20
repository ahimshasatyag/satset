import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.avatarUrl,
    required super.currentCity,
    required super.currentSubdistrict,
    required super.currentLatitude,
    required super.currentLongitude,
    super.hasUnreadCourierUpdates = true,
    super.unreadCount = 2,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Satria Perkasa',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      currentCity: json['currentCity'] as String? ?? 'Jakarta Selatan',
      currentSubdistrict:
          json['currentSubdistrict'] as String? ?? 'Kebayoran Baru',
      currentLatitude:
          (json['currentLatitude'] as num?)?.toDouble() ?? -6.2415,
      currentLongitude:
          (json['currentLongitude'] as num?)?.toDouble() ?? 106.8000,
      hasUnreadCourierUpdates:
          json['hasUnreadCourierUpdates'] as bool? ?? true,
      unreadCount: json['unreadCount'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'currentCity': currentCity,
      'currentSubdistrict': currentSubdistrict,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'hasUnreadCourierUpdates': hasUnreadCourierUpdates,
      'unreadCount': unreadCount,
    };
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      avatarUrl: entity.avatarUrl,
      currentCity: entity.currentCity,
      currentSubdistrict: entity.currentSubdistrict,
      currentLatitude: entity.currentLatitude,
      currentLongitude: entity.currentLongitude,
      hasUnreadCourierUpdates: entity.hasUnreadCourierUpdates,
      unreadCount: entity.unreadCount,
    );
  }
}
