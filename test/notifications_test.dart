import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:satset/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:satset/features/notifications/data/models/notification_item_model.dart';
import 'package:satset/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:satset/features/notifications/domain/entities/notification_item.dart';
import 'package:satset/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:satset/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:satset/features/notifications/domain/usecases/mark_all_notifications_as_read_usecase.dart';
import 'package:satset/features/notifications/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:satset/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:satset/features/notifications/presentation/bloc/notification_event.dart';
import 'package:satset/features/notifications/presentation/bloc/notification_state.dart';
import 'package:satset/features/notifications/presentation/pages/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notifications Feature Clean Architecture Tests', () {
    late NotificationRemoteDataSource remoteDataSource;
    late NotificationLocalDataSource localDataSource;
    late NotificationRepositoryImpl repository;
    late GetNotificationsUseCase getNotificationsUseCase;
    late MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
    late MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase;
    late DeleteNotificationUseCase deleteNotificationUseCase;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      remoteDataSource = NotificationRemoteDataSourceImpl();
      localDataSource = NotificationLocalDataSourceImpl();
      repository = NotificationRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      getNotificationsUseCase = GetNotificationsUseCase(repository);
      markNotificationAsReadUseCase = MarkNotificationAsReadUseCase(repository);
      markAllNotificationsAsReadUseCase =
          MarkAllNotificationsAsReadUseCase(repository);
      deleteNotificationUseCase = DeleteNotificationUseCase(repository);
    });

    test('NotificationItemModel serialization & deserialization works properly', () {
      final now = DateTime.now();
      final model = NotificationItemModel(
        id: 'notif-100',
        userId: 'usr-01',
        title: 'Paket Sedang Diantar',
        message: 'Kurir SatSet sedang menuju lokasi Anda.',
        type: NotificationType.shipment,
        isRead: false,
        createdAt: now,
        shipmentId: 'ship-123',
        metadata: const {'nomor_resi': 'SATSET-001'},
      );

      final json = model.toJson();
      expect(json['id'], equals('notif-100'));
      expect(json['type'], equals('shipment'));
      expect(json['shipmentId'], equals('ship-123'));

      final reconstructed = NotificationItemModel.fromJson(json);
      expect(reconstructed.id, equals(model.id));
      expect(reconstructed.type, equals(NotificationType.shipment));
      expect(reconstructed.isShipment, isTrue);
      expect(reconstructed.isPayment, isFalse);

      final dbRow = {
        'id': 'notif-200',
        'user_id': 'usr-02',
        'title': 'Pembayaran Berhasil',
        'message': 'Tagihan pengiriman telah lunas.',
        'type': 'payment',
        'is_read': true,
        'created_at': now.toIso8601String(),
        'payment_id': 'pay-99',
      };

      final fromDb = NotificationItemModel.fromDatabase(dbRow);
      expect(fromDb.id, equals('notif-200'));
      expect(fromDb.type, equals(NotificationType.payment));
      expect(fromDb.isRead, isTrue);
      expect(fromDb.paymentId, equals('pay-99'));
    });

    test('NotificationRepository gets notifications and caches locally', () async {
      final notifications = await repository.getNotifications();
      expect(notifications.isNotEmpty, isTrue);

      final cached = await localDataSource.getCachedNotifications();
      expect(cached.isNotEmpty, isTrue);
      expect(cached.length, equals(notifications.length));

      final unreadCount = await repository.getUnreadCount();
      expect(unreadCount >= 0, isTrue);
    });

    test('NotificationRepository mark as read and delete work properly', () async {
      final notifications = await repository.getNotifications();
      final firstId = notifications.first.id;

      await repository.markAsRead(firstId);
      final cachedAfterRead = await localDataSource.getCachedNotifications();
      final readItem = cachedAfterRead.firstWhere((n) => n.id == firstId);
      expect(readItem.isRead, isTrue);

      await repository.markAllAsRead();
      final cachedAfterAllRead = await localDataSource.getCachedNotifications();
      expect(cachedAfterAllRead.every((n) => n.isRead), isTrue);

      await repository.deleteNotification(firstId);
      final cachedAfterDelete = await localDataSource.getCachedNotifications();
      expect(cachedAfterDelete.any((n) => n.id == firstId), isFalse);
    });

    test('NotificationBloc handles load, filter, search, mark read, and delete', () async {
      final bloc = NotificationBloc(
        getNotificationsUseCase: getNotificationsUseCase,
        markNotificationAsReadUseCase: markNotificationAsReadUseCase,
        markAllNotificationsAsReadUseCase: markAllNotificationsAsReadUseCase,
        deleteNotificationUseCase: deleteNotificationUseCase,
        repository: repository,
      );

      // Tunggu hingga initial loading selesai
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<NotificationState>((s) =>
              s.status == NotificationStatus.success &&
              s.notifications.isNotEmpty),
        ),
      );

      final initialCount = bloc.state.notifications.length;
      expect(initialCount > 0, isTrue);

      // Uji filter Pengiriman
      bloc.add(const NotificationFilterChanged(NotificationFilter.shipment));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>((s) =>
              s.activeFilter == NotificationFilter.shipment &&
              s.filteredNotifications.every((n) => n.isShipment)),
        ),
      );

      // Uji filter Pembayaran
      bloc.add(const NotificationFilterChanged(NotificationFilter.payment));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>((s) =>
              s.activeFilter == NotificationFilter.payment &&
              s.filteredNotifications.every((n) => n.isPayment)),
        ),
      );

      // Uji filter Belum Dibaca
      bloc.add(const NotificationFilterChanged(NotificationFilter.unread));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>((s) =>
              s.activeFilter == NotificationFilter.unread &&
              s.filteredNotifications.every((n) => !n.isRead)),
        ),
      );

      // Kembalikan ke filter Semua
      bloc.add(const NotificationFilterChanged(NotificationFilter.all));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>(
              (s) => s.activeFilter == NotificationFilter.all),
        ),
      );

      // Uji pencarian kata kunci
      bloc.add(const NotificationSearchQueryChanged('paket'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>((s) =>
              s.searchQuery == 'paket' &&
              s.filteredNotifications.every((n) =>
                  n.title.toLowerCase().contains('paket') ||
                  n.message.toLowerCase().contains('paket'))),
        ),
      );

      // Hapus pencarian
      bloc.add(const NotificationSearchQueryChanged(''));
      await expectLater(
        bloc.stream,
        emits(
          predicate<NotificationState>((s) => s.searchQuery == ''),
        ),
      );

      // Uji tandai semua dibaca
      bloc.add(const NotificationMarkAllAsReadSubmitted());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<NotificationState>((s) =>
              s.unreadCount == 0 &&
              s.notifications.every((n) => n.isRead)),
        ),
      );

      await bloc.close();
    });

    testWidgets('NotificationsPage renders search, filter tabs, and notification cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pemberitahuan'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Belum Dibaca'), findsOneWidget);
      expect(find.text('Pengiriman'), findsWidgets);
      expect(find.text('Pembayaran'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
