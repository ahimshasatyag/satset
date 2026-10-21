import '../entities/user_profile.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk mengambil data profil pelanggan dari m_users
class GetUserProfileUseCase {
  final DashboardRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<UserProfile> call({String? userId}) {
    return repository.getUserProfile(userId: userId);
  }
}
