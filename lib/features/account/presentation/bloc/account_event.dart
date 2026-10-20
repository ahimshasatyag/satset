import 'package:equatable/equatable.dart';

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

/// Pengguna mengonfirmasi keluar dari sesi akun
class AccountLogoutSubmitted extends AccountEvent {
  const AccountLogoutSubmitted();
}
