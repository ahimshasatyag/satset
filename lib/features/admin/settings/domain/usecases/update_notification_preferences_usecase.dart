import '../entities/notification_preferences.dart';
import '../repositories/admin_settings_repository.dart';

class UpdateNotificationPreferencesUseCase {
  final AdminSettingsRepository repository;

  const UpdateNotificationPreferencesUseCase(this.repository);

  Future<NotificationPreferences> call(NotificationPreferences preferences) {
    return repository.updateNotificationPreferences(preferences);
  }
}

