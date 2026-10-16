import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case untuk mengambil data user yang sedang aktif login
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<User?> call() async {
    return await repository.getCurrentUser();
  }
}
