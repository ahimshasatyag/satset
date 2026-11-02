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

class AdminAuthCheckRequested extends AdminAuthEvent {
  const AdminAuthCheckRequested();
}

class AdminAuthLogoutRequested extends AdminAuthEvent {
  const AdminAuthLogoutRequested();
}

class AdminAuthResetState extends AdminAuthEvent {
  const AdminAuthResetState();
}

