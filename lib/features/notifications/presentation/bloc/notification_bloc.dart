import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final NotificationRepository repository;

  StreamSubscription<List<NotificationItem>>? _realtimeSubscription;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllNotificationsAsReadUseCase,
    required this.deleteNotificationUseCase,
    required this.repository,
  }) : super(const NotificationState()) {
    on<NotificationLoadStarted>(_onLoadStarted);
    on<NotificationFilterChanged>(_onFilterChanged);
    on<NotificationSearchQueryChanged>(_onSearchQueryChanged);
    on<NotificationMarkAsReadSubmitted>(_onMarkAsReadSubmitted);
    on<NotificationMarkAllAsReadSubmitted>(_onMarkAllAsReadSubmitted);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationClearAllSubmitted>(_onClearAllSubmitted);
    on<NotificationRealtimeUpdated>(_onRealtimeUpdated);

    // Mulai dengarkan pembaruan real-time dari Supabase
    _startRealtimeSubscription();

    // Muat data awal
    add(const NotificationLoadStarted());
  }

  void _startRealtimeSubscription() {
    _realtimeSubscription?.cancel();
    try {
      _realtimeSubscription = repository.subscribeNotifications().listen(
        (items) {
          add(NotificationRealtimeUpdated(items));
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }

  List<NotificationItem> _applyFilterAndSearch(
    List<NotificationItem> source,
    NotificationFilter filter,
    String query,
  ) {
    var filtered = source;

    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
    } else if (filter == NotificationFilter.payment) {
      filtered = filtered.where((n) => n.isPayment).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.message.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }

  Future<void> _onLoadStarted(
    NotificationLoadStarted event,
    Emitter<NotificationState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(
        status: NotificationStatus.loading,
        clearError: true,
        clearAction: true,
      ));
    }

    try {
      final items = await getNotificationsUseCase();
      final unread = items.where((n) => !n.isRead).length;

      final filtered =
          _applyFilterAndSearch(items, state.activeFilter, state.searchQuery);

      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: items,
        filteredNotifications: filtered,
        unreadCount: unread,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: 'Gagal memuat pemberitahuan: ${e.toString()}',
      ));
    }
  }

  void _onFilterChanged(
    NotificationFilterChanged event,
    Emitter<NotificationState> emit,
  ) {
    final filtered = _applyFilterAndSearch(
      state.notifications,
      event.filter,
      state.searchQuery,
    );

    emit(state.copyWith(
      activeFilter: event.filter,
      filteredNotifications: filtered,
      clearAction: true,
    ));
  }

  void _onSearchQueryChanged(
    NotificationSearchQueryChanged event,
    Emitter<NotificationState> emit,
  ) {
    final filtered = _applyFilterAndSearch(
      state.notifications,
      state.activeFilter,
      event.query,
    );

    emit(state.copyWith(
      searchQuery: event.query,
      filteredNotifications: filtered,
      clearAction: true,
    ));
  }

  Future<void> _onMarkAsReadSubmitted(
    NotificationMarkAsReadSubmitted event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    final unread = updatedList.where((n) => !n.isRead).length;
    final filtered =
        _applyFilterAndSearch(updatedList, state.activeFilter, state.searchQuery);

    emit(state.copyWith(
      notifications: updatedList,
      filteredNotifications: filtered,
      unreadCount: unread,
      actionMessage: 'Notifikasi ditandai sudah dibaca.',
    ));

    try {
      await markNotificationAsReadUseCase(event.notificationId);
    } catch (_) {}
  }

  Future<void> _onMarkAllAsReadSubmitted(
    NotificationMarkAllAsReadSubmitted event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList = state.notifications.map((n) {
      return n.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();

    final filtered =
        _applyFilterAndSearch(updatedList, state.activeFilter, state.searchQuery);

    emit(state.copyWith(
      notifications: updatedList,
      filteredNotifications: filtered,
      unreadCount: 0,
      actionMessage: 'Semua notifikasi berhasil ditandai dibaca.',
    ));

    try {
      await markAllNotificationsAsReadUseCase();
    } catch (_) {}
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList =
        state.notifications.where((n) => n.id != event.notificationId).toList();
    final unread = updatedList.where((n) => !n.isRead).length;
    final filtered =
        _applyFilterAndSearch(updatedList, state.activeFilter, state.searchQuery);

    emit(state.copyWith(
      notifications: updatedList,
      filteredNotifications: filtered,
      unreadCount: unread,
      actionMessage: 'Notifikasi telah dihapus.',
    ));

    try {
      await deleteNotificationUseCase(event.notificationId);
    } catch (_) {}
  }

  Future<void> _onClearAllSubmitted(
    NotificationClearAllSubmitted event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      notifications: [],
      filteredNotifications: [],
      unreadCount: 0,
      actionMessage: 'Seluruh notifikasi telah dibersihkan.',
    ));

    try {
      await deleteNotificationUseCase.clearAll();
    } catch (_) {}
  }

  void _onRealtimeUpdated(
    NotificationRealtimeUpdated event,
    Emitter<NotificationState> emit,
  ) {
    if (event.notifications.isEmpty) return;

    final unread = event.notifications.where((n) => !n.isRead).length;
    final filtered = _applyFilterAndSearch(
      event.notifications,
      state.activeFilter,
      state.searchQuery,
    );

    emit(state.copyWith(
      status: NotificationStatus.success,
      notifications: event.notifications,
      filteredNotifications: filtered,
      unreadCount: unread,
    ));
  }
}
