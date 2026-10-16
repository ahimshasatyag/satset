import 'package:equatable/equatable.dart';

/// Basis class untuk semua event di AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memeriksa status login saat aplikasi dibuka
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event saat form login disubmit dengan email & kata sandi
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Event saat form registrasi akun baru disubmit
class AuthRegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const AuthRegisterSubmitted({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

/// Event saat pengguna menekan tombol login Google
class AuthGoogleLoginSubmitted extends AuthEvent {
  const AuthGoogleLoginSubmitted();
}

/// Event saat pengguna mengirim permohonan reset password
class AuthForgotPasswordSubmitted extends AuthEvent {
  final String email;

  const AuthForgotPasswordSubmitted(this.email);

  @override
  List<Object?> get props => [email];
}

/// Event saat pengguna melakukan logout
class AuthLogoutSubmitted extends AuthEvent {
  const AuthLogoutSubmitted();
}

/// Event untuk mereset state error/success kembali ke initial
class AuthResetState extends AuthEvent {
  const AuthResetState();
}
