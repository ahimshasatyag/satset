import 'package:equatable/equatable.dart';
import '../../domain/entities/user_account.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Permintaan pemuatan data profil akun pengguna
class AccountProfileLoaded extends AccountEvent {
  const AccountProfileLoaded();
}

/// Pengguna mengaktifkan / menonaktifkan notifikasi
class AccountNotificationsToggled extends AccountEvent {
  final bool isEnabled;

  const AccountNotificationsToggled(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

/// Pengguna memperbarui profil (nama, nomor telepon, email opsional, dan foto avatar)
class AccountProfileUpdated extends AccountEvent {
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;

  const AccountProfileUpdated({
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [name, phone, email, avatarUrl];
}

/// Pengguna mengubah kata sandi akun via Supabase Auth
class AccountPasswordChanged extends AccountEvent {
  final String newPassword;

  const AccountPasswordChanged(this.newPassword);

  @override
  List<Object?> get props => [newPassword];
}

/// Pengguna meminta kirim ulang verifikasi email
class AccountEmailVerificationResent extends AccountEvent {
  const AccountEmailVerificationResent();
}

/// Menyimpan atau memperbarui alamat pelanggan
class AccountAddressSaved extends AccountEvent {
  final UserAddress address;

  const AccountAddressSaved(this.address);

  @override
  List<Object?> get props => [address];
}

/// Menghapus alamat pelanggan berdasarkan ID
class AccountAddressDeleted extends AccountEvent {
  final String addressId;

  const AccountAddressDeleted(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

/// Menetapkan alamat utama pelanggan
class AccountPrimaryAddressSet extends AccountEvent {
  final String addressId;

  const AccountPrimaryAddressSet(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

/// Pengguna mengonfirmasi keluar dari sesi akun
class AccountLogoutSubmitted extends AccountEvent {
  const AccountLogoutSubmitted();
}
