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
  }) {
    return repository.getNotifications(
      limit: limit,
      offset: offset,
      filter: filter,
      searchQuery: searchQuery,
    );
  }

  Future<int> getUnreadCount() {
    return repository.getUnreadCount();
  }

  Stream<List<NotificationItem>> subscribe() {
    return repository.subscribeNotifications();
  }
}
