import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_item.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Permintaan pemuatan notifikasi awal atau pull-to-refresh
class NotificationLoadStarted extends NotificationEvent {
  final bool isRefresh;
  final bool isCourier;
  final String? courierId;
  final String? userId;

  const NotificationLoadStarted({
    this.isRefresh = false,
    this.isCourier = false,
    this.courierId,
    this.userId,
  });

  @override
  List<Object?> get props => [isRefresh, isCourier, courierId, userId];
}

/// Pengguna mengganti filter kategori
class NotificationFilterChanged extends NotificationEvent {
  final NotificationFilter filter;

  const NotificationFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Pengguna mengetik kata kunci pencarian notifikasi
class NotificationSearchQueryChanged extends NotificationEvent {
  final String query;

  const NotificationSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Menandai satu notifikasi sebagai sudah dibaca
class NotificationMarkAsReadSubmitted extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsReadSubmitted(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Menandai seluruh notifikasi yang belum dibaca sebagai sudah dibaca
class NotificationMarkAllAsReadSubmitted extends NotificationEvent {
  final bool isCourier;
  final String? courierId;
  final String? userId;

  const NotificationMarkAllAsReadSubmitted({
    this.isCourier = false,
    this.courierId,
    this.userId,
  });

  @override
  List<Object?> get props => [isCourier, courierId, userId];
}

/// Menghapus satu notifikasi
class NotificationDeleted extends NotificationEvent {
  final String notificationId;

  const NotificationDeleted(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Menghapus semua notifikasi
class NotificationClearAllSubmitted extends NotificationEvent {
  final bool isCourier;
  final String? courierId;
  final String? userId;

  const NotificationClearAllSubmitted({
    this.isCourier = false,
    this.courierId,
    this.userId,
  });

  @override
  List<Object?> get props => [isCourier, courierId, userId];
}

/// Pembaruan streaming Supabase Realtime ketika ada perubahan data
class NotificationRealtimeUpdated extends NotificationEvent {
  final List<NotificationItem> notifications;

  const NotificationRealtimeUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

/// Menambahkan notifikasi baru ke database Supabase
class NotificationCreated extends NotificationEvent {
  final String title;
  final String message;
  final NotificationType type;
  final String? shipmentId;
  final bool isCourier;
  final String? courierId;

  const NotificationCreated({
    required this.title,
    required this.message,
    this.type = NotificationType.system,
    this.shipmentId,
    this.isCourier = false,
    this.courierId,
  });

  @override
  List<Object?> get props =>
      [title, message, type, shipmentId, isCourier, courierId];
}

