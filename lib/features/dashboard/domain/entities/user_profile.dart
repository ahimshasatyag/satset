import 'package:equatable/equatable.dart';

/// Entity profil ringkas pengguna untuk Dashboard
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String currentCity;
  final String currentSubdistrict;
  final double currentLatitude;
  final double currentLongitude;
  final bool hasUnreadCourierUpdates;
  final int unreadCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.currentCity,
    required this.currentSubdistrict,
    required this.currentLatitude,
    required this.currentLongitude,
    this.hasUnreadCourierUpdates = true,
    this.unreadCount = 2,
  });

  /// Sapaan waktu kontekstual dinamis (Pagi, Siang, Sore, Malam)
  String get timeGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String get locationDisplay => '$currentSubdistrict, $currentCity';

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? currentCity,
    String? currentSubdistrict,
    double? currentLatitude,
    double? currentLongitude,
    bool? hasUnreadCourierUpdates,
    int? unreadCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentCity: currentCity ?? this.currentCity,
      currentSubdistrict: currentSubdistrict ?? this.currentSubdistrict,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      hasUnreadCourierUpdates:
          hasUnreadCourierUpdates ?? this.hasUnreadCourierUpdates,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        currentCity,
        currentSubdistrict,
        currentLatitude,
        currentLongitude,
        hasUnreadCourierUpdates,
        unreadCount,
      ];
}
