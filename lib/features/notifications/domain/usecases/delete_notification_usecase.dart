import '../repositories/notification_repository.dart';

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<void> call(String notificationId, {bool isCourier = false}) {
    return repository.deleteNotification(notificationId, isCourier: isCourier);
  }

  Future<void> clearAll({bool isCourier = false, String? courierId}) {
    return repository.clearAllNotifications(
      isCourier: isCourier,
      courierId: courierId,
    );
  }
}
