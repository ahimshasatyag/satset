import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_user.dart';

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  final String? message;

  const AdminAuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AdminAuthSuccess extends AdminAuthState {
  final AdminUser adminUser;
  final String message;
  final String? password;

  const AdminAuthSuccess({
    required this.adminUser,
    this.message = 'Selamat datang kembali di Admin Portal SatSet!',
    this.password,
  });

  @override
  List<Object?> get props => [adminUser, message, password];
}

class AdminAuthFailure extends AdminAuthState {
  final String errorMessage;

  const AdminAuthFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class AdminAuthUnauthenticated extends AdminAuthState {
  final String? savedEmail;
  final bool rememberMe;

  const AdminAuthUnauthenticated({
    this.savedEmail,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [savedEmail, rememberMe];
}

