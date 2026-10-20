import '../../domain/entities/user_account.dart';

class UserAccountModel extends UserAccount {
  const UserAccountModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.membershipTier = 'SatSet Priority Member',
    super.satsetPayBalance = 450000,
    super.savedAddressesCount = 3,
    super.insuranceClaimsCount = 0,
    super.isNotificationsEnabled = true,
    super.avatarUrl,
  });

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      id: json['id'] as String? ?? 'usr-01',
      name: json['name'] as String? ?? 'Satria Perkasa',
      email: json['email'] as String? ?? 'satria@satset.id',
      phone: json['phone'] as String? ?? '+62 812-3456-7890',
      membershipTier:
          json['membershipTier'] as String? ?? 'SatSet Priority Member',
      satsetPayBalance: json['satsetPayBalance'] as int? ?? 450000,
      savedAddressesCount: json['savedAddressesCount'] as int? ?? 3,
      insuranceClaimsCount: json['insuranceClaimsCount'] as int? ?? 0,
      isNotificationsEnabled:
          json['isNotificationsEnabled'] as bool? ?? true,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  factory UserAccountModel.fromEntity(UserAccount entity) {
    return UserAccountModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      membershipTier: entity.membershipTier,
      satsetPayBalance: entity.satsetPayBalance,
      savedAddressesCount: entity.savedAddressesCount,
      insuranceClaimsCount: entity.insuranceClaimsCount,
      isNotificationsEnabled: entity.isNotificationsEnabled,
      avatarUrl: entity.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'membershipTier': membershipTier,
      'satsetPayBalance': satsetPayBalance,
      'savedAddressesCount': savedAddressesCount,
      'insuranceClaimsCount': insuranceClaimsCount,
      'isNotificationsEnabled': isNotificationsEnabled,
      'avatarUrl': avatarUrl,
    };
  }
}
