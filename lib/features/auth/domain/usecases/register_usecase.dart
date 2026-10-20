import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameter untuk registrasi akun baru
class RegisterParams {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? alamatLengkap;
  final double? latitude;
  final double? longitude;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.alamatLengkap,
    this.latitude,
    this.longitude,
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
      alamatLengkap: params.alamatLengkap,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
