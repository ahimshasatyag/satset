import '../repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<void> call(String notificationId, {bool isCourier = false}) {
    return repository.markAsRead(notificationId, isCourier: isCourier);
  }
}
