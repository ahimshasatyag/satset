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

  const NotificationLoadStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Pengguna mengganti filter kategori (Semua, Belum Dibaca, Pengiriman, Pembayaran)
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
  const NotificationMarkAllAsReadSubmitted();
}

/// Menghapus satu notifikasi pelanggan
class NotificationDeleted extends NotificationEvent {
  final String notificationId;

  const NotificationDeleted(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Menghapus semua notifikasi
class NotificationClearAllSubmitted extends NotificationEvent {
  const NotificationClearAllSubmitted();
}

/// Pembaruan streaming Supabase Realtime ketika ada perubahan data
class NotificationRealtimeUpdated extends NotificationEvent {
  final List<NotificationItem> notifications;

  const NotificationRealtimeUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}
