import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Basis class untuk seluruh state autentikasi
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State awal
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State saat proses autentikasi sedang berjalan di latar belakang
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State ketika autentikasi berhasil (login/register/google)
class AuthSuccess extends AuthState {
  final User user;
  final String message;

  const AuthSuccess({
    required this.user,
    this.message = 'Autentikasi berhasil',
  });

  @override
  List<Object?> get props => [user, message];
}

/// State ketika pendaftaran akun baru berhasil (menunggu verifikasi email)
class AuthRegisterSuccess extends AuthState {
  final User user;
  final String message;

  const AuthRegisterSuccess({
    required this.user,
    this.message = 'Pendaftaran akun SatSet berhasil! Silakan verifikasi email Anda.',
  });

  @override
  List<Object?> get props => [user, message];
}

/// State ketika autentikasi gagal
class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// State saat pengguna tidak dalam keadaan login (unauthenticated)
class AuthUnauthenticated extends AuthState {
  final String? savedEmail;
  final bool rememberMe;

  const AuthUnauthenticated({
    this.savedEmail,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [savedEmail, rememberMe];
}

/// State ketika email reset password berhasil dikirim
class AuthForgotPasswordSuccess extends AuthState {
  final String email;

  const AuthForgotPasswordSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

/// State ketika kode unik OTP email berhasil diverifikasi
class AuthCodeVerifiedSuccess extends AuthState {
  final String email;
  final String code;

  const AuthCodeVerifiedSuccess({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// State ketika kata sandi baru berhasil disimpan
class AuthResetPasswordSuccess extends AuthState {
  final String message;

  const AuthResetPasswordSuccess({
    this.message = 'Kata sandi berhasil diperbarui! Silakan masuk kembali.',
  });

  @override
  List<Object?> get props => [message];
}

/// State ketika kode verifikasi baru berhasil dikirim ulang
class AuthResendCodeSuccess extends AuthState {
  final String email;
  final String message;

  const AuthResendCodeSuccess({
    required this.email,
    this.message = 'Kode verifikasi baru telah dikirimkan ke email Anda.',
  });

  @override
  List<Object?> get props => [email, message];
}
