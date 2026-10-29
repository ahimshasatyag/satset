import '../repositories/notification_repository.dart';

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUseCase(this.repository);

  Future<void> call({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return repository.markAllAsRead(
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
  }
}
