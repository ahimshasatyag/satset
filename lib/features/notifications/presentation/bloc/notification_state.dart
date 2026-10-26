import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_item.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationItem> notifications;
  final List<NotificationItem> filteredNotifications;
  final int unreadCount;
  final NotificationFilter activeFilter;
  final String searchQuery;
  final String? errorMessage;
  final String? actionMessage;
  final bool isCourier;
  final String? courierId;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.filteredNotifications = const [],
    this.unreadCount = 0,
    this.activeFilter = NotificationFilter.all,
    this.searchQuery = '',
    this.errorMessage,
    this.actionMessage,
    this.isCourier = false,
    this.courierId,
  });

  bool get isLoading => status == NotificationStatus.loading;
  bool get hasUnread => unreadCount > 0;
  bool get isEmpty => filteredNotifications.isEmpty;

  /// Mengelompokkan notifikasi terfilter berdasarkan tanggal (Hari Ini, Kemarin, Minggu Ini, Terdahulu)
  Map<String, List<NotificationItem>> get groupedNotifications {
    final Map<String, List<NotificationItem>> map = {
      'Hari Ini': [],
      'Kemarin': [],
      'Minggu Ini': [],
      'Terdahulu': [],
    };

    for (final item in filteredNotifications) {
      final category = item.dateCategory;
      if (map.containsKey(category)) {
        map[category]!.add(item);
      } else {
        map[category] = [item];
      }
    }

    // Buang grup yang kosong agar tampilan rapi
    map.removeWhere((key, value) => value.isEmpty);
    return map;
  }

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationItem>? notifications,
    List<NotificationItem>? filteredNotifications,
    int? unreadCount,
    NotificationFilter? activeFilter,
    String? searchQuery,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearAction = false,
    bool? isCourier,
    String? courierId,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      filteredNotifications:
          filteredNotifications ?? this.filteredNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage:
          clearAction ? null : (actionMessage ?? this.actionMessage),
      isCourier: isCourier ?? this.isCourier,
      courierId: courierId ?? this.courierId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        filteredNotifications,
        unreadCount,
        activeFilter,
        searchQuery,
        errorMessage,
        actionMessage,
        isCourier,
        courierId,
      ];
}
