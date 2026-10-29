import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class CreateNotificationUseCase {
  final NotificationRepository repository;

  CreateNotificationUseCase(this.repository);

  Future<NotificationItem> call({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? shipmentId,
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return repository.createNotification(
      title: title,
      message: message,
      type: type,
      shipmentId: shipmentId,
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
  }
}
