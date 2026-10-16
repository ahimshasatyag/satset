import '../repositories/splash_repository.dart';

/// Use case untuk memeriksa status autentikasi / login pengguna
class CheckAuthStatusUseCase {
  final SplashRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<bool> call() async {
    return await repository.checkAuthStatus();
  }
}
