import 'package:equatable/equatable.dart';

/// Entity profil ringkas pengguna untuk Dashboard Customer SatSet
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String? alamatLengkap;
  final String currentCity;
  final String currentSubdistrict;
  final double currentLatitude;
  final double currentLongitude;
  final bool hasUnreadCourierUpdates;
  final int unreadCount;

  const UserProfile({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.avatarUrl = '',
    this.alamatLengkap,
    this.currentCity = 'Jakarta',
    this.currentSubdistrict = 'Pusat',
    this.currentLatitude = -6.2088,
    this.currentLongitude = 106.8456,
    this.hasUnreadCourierUpdates = false,
    this.unreadCount = 0,
  });

  static const empty = UserProfile(id: '', name: 'Pelanggan');

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

  /// Teks sapaan lengkap untuk pelanggan
  String get greetingDisplay => '$timeGreeting, $name! 👋';

  /// Tampilan lokasi sekarang pengguna (bukan alamat rumah/jalan statis)
  String get currentLocationDisplay {
    if (currentSubdistrict.isNotEmpty && currentCity.isNotEmpty) {
      if (currentSubdistrict.toLowerCase() == currentCity.toLowerCase()) {
        return currentCity;
      }
      return '$currentSubdistrict, $currentCity';
    }
    if (currentCity.isNotEmpty) return currentCity;
    return '';
  }

  /// Teks lokasi pengguna di header/dashboard (mengarah ke lokasi sekarang, bukan alamat rumah)
  String get locationDisplay => currentLocationDisplay;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? alamatLengkap,
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
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
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
    email,
    phone,
    avatarUrl,
    alamatLengkap,
    currentCity,
    currentSubdistrict,
    currentLatitude,
    currentLongitude,
    hasUnreadCourierUpdates,
    unreadCount,
  ];
}
