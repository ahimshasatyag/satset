import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameter untuk login biasa
class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
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
    );
  }

  /// Eksekusi login menggunakan akun Google
  Future<User> withGoogle() async {
    return await repository.loginWithGoogle();
  }
}
