import '../repositories/notification_repository.dart';

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUseCase(this.repository);

  Future<void> call({bool isCourier = false, String? courierId}) {
    return repository.markAllAsRead(isCourier: isCourier, courierId: courierId);
  }
}
