import '../entities/user_profile.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk mengambil data profil, GPS, dan indikator notifikasi
class GetUserProfileUseCase {
  final DashboardRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<UserProfile> call() {
    return repository.getUserProfile();
  }
}
