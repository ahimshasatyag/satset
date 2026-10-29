import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationItem>> call({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return repository.getNotifications(
      limit: limit,
      offset: offset,
      filter: filter,
      searchQuery: searchQuery,
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
  }

  Future<int> getUnreadCount({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return repository.getUnreadCount(
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
  }

  Stream<List<NotificationItem>> subscribe({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return repository.subscribeNotifications(
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
  }
}
