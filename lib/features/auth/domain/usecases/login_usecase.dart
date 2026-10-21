import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameter untuk login biasa
class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;
  final double? latitude;
  final double? longitude;

  const LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.latitude,
    this.longitude,
  });
}

/// Use case untuk memproses login pengguna (email/password & Google)
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Eksekusi login menggunakan email dan password
  Future<User> call(LoginParams params) async {
    return await repository.login(
      email: params.email,
      password: params.password,
      rememberMe: params.rememberMe,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }

  /// Eksekusi login menggunakan akun Google
  Future<User> withGoogle() async {
    return await repository.loginWithGoogle();
  }
}
