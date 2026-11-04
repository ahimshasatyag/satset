import 'package:equatable/equatable.dart';

abstract class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();

  @override
  List<Object?> get props => [];
}

class AdminAuthLoginSubmitted extends AdminAuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AdminAuthLoginSubmitted({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AdminAuthRegisterSubmitted extends AdminAuthEvent {
  final String namaLengkap;
  final String email;
  final String password;
  final String? noHp;
  final String? employeeCode;
  final String? alamatLengkap;
  final String? fotoUrl;

  const AdminAuthRegisterSubmitted({
    required this.namaLengkap,
    required this.email,
    required this.password,
    this.noHp,
    this.employeeCode,
    this.alamatLengkap,
    this.fotoUrl,
  });

  @override
  List<Object?> get props => [
        namaLengkap,
        email,
        password,
        noHp,
        employeeCode,
        alamatLengkap,
        fotoUrl,
      ];
}

class AdminAuthCheckRequested extends AdminAuthEvent {
  const AdminAuthCheckRequested();
}

class AdminAuthLogoutRequested extends AdminAuthEvent {
  const AdminAuthLogoutRequested();
}

class AdminAuthResetState extends AdminAuthEvent {
  const AdminAuthResetState();
}

