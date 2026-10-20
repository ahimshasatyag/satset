import 'package:equatable/equatable.dart';

/// Entity profil & informasi akun pengguna
class UserAccount extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String membershipTier;
  final int satsetPayBalance;
  final int savedAddressesCount;
  final int insuranceClaimsCount;
  final bool isNotificationsEnabled;
  final String? avatarUrl;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.membershipTier = 'SatSet Priority Member',
    this.satsetPayBalance = 450000,
    this.savedAddressesCount = 3,
    this.insuranceClaimsCount = 0,
    this.isNotificationsEnabled = true,
    this.avatarUrl,
  });

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? membershipTier,
    int? satsetPayBalance,
    int savedAddressesCount = 3,
    int? insuranceClaimsCount,
    bool? isNotificationsEnabled,
    String? avatarUrl,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      membershipTier: membershipTier ?? this.membershipTier,
      satsetPayBalance: satsetPayBalance ?? this.satsetPayBalance,
      savedAddressesCount: savedAddressesCount,
      insuranceClaimsCount: insuranceClaimsCount ?? this.insuranceClaimsCount,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        membershipTier,
        satsetPayBalance,
        savedAddressesCount,
        insuranceClaimsCount,
        isNotificationsEnabled,
        avatarUrl,
      ];
}
