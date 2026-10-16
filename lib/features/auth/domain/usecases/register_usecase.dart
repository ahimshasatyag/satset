import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameter untuk registrasi akun baru
class RegisterParams {
  final String name;
  final String email;
  final String phone;
  final String password;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}

/// Use case untuk mendaftarkan akun pengguna baru
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> call(RegisterParams params) async {
    return await repository.register(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
    );
  }
}
