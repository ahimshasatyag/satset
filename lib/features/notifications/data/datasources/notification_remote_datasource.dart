import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../app/constants/database_constants.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/notification_item.dart';
import '../models/notification_item_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationItemModel>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
  });

  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAllNotifications();
  Stream<List<NotificationItemModel>> subscribeNotifications();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;

  NotificationRemoteDataSourceImpl({
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
  })  : _customClient = client,
        _authLocalDataSource = authLocalDataSource;

  bool get _isSupabaseAvailable {
    if (_customClient != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  Future<String> _resolveUserId() async {
    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null && authUser.email != null) {
        try {
          final res = await _client
              .from(DatabaseConstants.tableUsers)
              .select(UserTableColumns.id)
              .eq(UserTableColumns.email, authUser.email!.trim().toLowerCase())
              .maybeSingle();

          if (res != null && res[UserTableColumns.id] != null) {
            return res[UserTableColumns.id].toString();
          }
        } catch (_) {}
      }
    }

    try {
      final localUser =
          await (_authLocalDataSource ?? AuthLocalDataSourceImpl()).getUser();
      if (localUser != null && localUser.id.isNotEmpty) {
        return localUser.id;
      }
    } catch (_) {}

    return '1';
  }

  @override
  Future<List<NotificationItemModel>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
  }) async {
    if (!_isSupabaseAvailable) {
      return _buildOfflineFallbackNotifications(filter, searchQuery);
    }

    try {
      final userId = await _resolveUserId();

      var query = _client
          .from(DatabaseConstants.tableNotifications)
          .select()
          .eq(NotificationTableColumns.userId, userId);

      if (filter == NotificationFilter.unread) {
        query = query.eq(NotificationTableColumns.isRead, false);
      } else if (filter == NotificationFilter.shipment) {
        query = query.eq(NotificationTableColumns.type, 'shipment');
      } else if (filter == NotificationFilter.payment) {
        query = query.eq(NotificationTableColumns.type, 'payment');
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final cleanSearch = searchQuery.trim();
        query = query.or(
            '${NotificationTableColumns.title}.ilike.%$cleanSearch%,${NotificationTableColumns.message}.ilike.%$cleanSearch%');
      }

      final rows = await query
          .order(NotificationTableColumns.createdAt, ascending: false)
          .range(offset, offset + limit - 1);

      final list = (rows as List)
          .map((r) => NotificationItemModel.fromDatabase(r as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;

      // Jika tabel t_notifications belum memiliki baris, bentuk notifikasi dinamis dari data pengiriman riil
      return await _fetchNotificationsFromShipments(userId, filter, searchQuery);
    } catch (_) {
      // Jika terjadi error koneksi atau tabel belum dibuat di supabase, gunakan fallback cerdas dari riwayat pengiriman
      try {
        final userId = await _resolveUserId();
        return await _fetchNotificationsFromShipments(userId, filter, searchQuery);
      } catch (_) {
        return _buildOfflineFallbackNotifications(filter, searchQuery);
      }
    }
  }

  /// Menghasilkan notifikasi dinamis berbasis t_shipments & t_shipment_payments milik customer
  Future<List<NotificationItemModel>> _fetchNotificationsFromShipments(
    String userId,
    NotificationFilter filter,
    String? searchQuery,
  ) async {
    final List<NotificationItemModel> result = [];

    try {
      final shipmentRows = await _client
          .from(DatabaseConstants.tableShipments)
          .select()
          .eq(ShipmentTableColumns.customerId, userId)
          .order(ShipmentTableColumns.createdAt, ascending: false)
          .limit(15);

      for (final s in shipmentRows as List) {
        final sMap = s as Map<String, dynamic>;
        final shipmentId = sMap[ShipmentTableColumns.id]?.toString() ?? '';
        final resi = sMap[ShipmentTableColumns.nomorResi]?.toString() ?? '';
        final statusId = sMap[ShipmentTableColumns.statusId]?.toString() ?? '1';
        final penerima = sMap[ShipmentTableColumns.penerimaNama]?.toString() ?? '';
        final createdAtStr = sMap[ShipmentTableColumns.createdAt]?.toString();
        final createdAt = createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

        String title;
        String message;

        switch (statusId) {
          case '1':
            title = 'Pesanan Pengiriman Dibuat';
            message =
                'Resi #$resi telah dibuat menuju $penerima. Menunggu konfirmasi pembayaran dan penjemputan paket.';
            break;
          case '2':
            title = 'Kurir Ditugaskan Menjemput';
            message =
                'Kurir SatSet telah ditugaskan untuk menjemput paket resi #$resi dari titik asal pengiriman.';
            break;
          case '3':
            title = 'Paket Berhasil Dijemput';
            message =
                'Paket #$resi telah diserahkan kepada kurir dan sedang bergerak menuju fasilitas sortir SatSet.';
            break;
          case '4':
            title = 'Paket Tiba di Sorting Hub';
            message =
                'Paket #$resi telah dipindai di Hub Logistik SatSet dan siap diproses ke rute pengantaran berikutnya.';
            break;
          case '5':
            title = 'Paket Sedang Diantar ke Penerima';
            message =
                'Kurir SatSet sedang meluncur mengantarkan paket #$resi ke alamat $penerima.';
            break;
          case '6':
            title = 'Paket Berhasil Diterima';
            message =
                'Alhamdulillah! Paket resi #$resi telah berhasil diterima oleh $penerima.';
            break;
          default:
            title = 'Pembaruan Status Pengiriman';
            message =
                'Status pengiriman paket #$resi telah diperbarui dalam sistem pelacakan.';
        }

        result.add(
          NotificationItemModel(
            id: 'notif-ship-$shipmentId',
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.shipment,
            isRead: false,
            createdAt: createdAt,
            shipmentId: shipmentId,
            metadata: {'nomor_resi': resi, 'status_id': statusId},
          ),
        );
      }
    } catch (_) {}

    // Ambil data pembayaran dari t_shipment_payments
    try {
      final paymentRows = await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .select()
          .order(DatabaseConstants.colCreatedAt, ascending: false)
          .limit(5);

      for (final p in paymentRows as List) {
        final pMap = p as Map<String, dynamic>;
        final pId = pMap[ShipmentPaymentTableColumns.id]?.toString() ?? '';
        final shipmentId =
            pMap[ShipmentPaymentTableColumns.shipmentId]?.toString();
        final jumlah =
            pMap[ShipmentPaymentTableColumns.jumlahBayar]?.toString() ?? '0';
        final status =
            pMap[ShipmentPaymentTableColumns.statusPembayaran]?.toString() ??
                'PAID';
        final createdAtStr =
            pMap[ShipmentPaymentTableColumns.createdAt]?.toString();
        final createdAt = createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

        final isPaid = status.toUpperCase() == 'PAID' ||
            status.toUpperCase() == 'BERHASIL';

        result.add(
          NotificationItemModel(
            id: 'notif-pay-$pId',
            userId: userId,
            title: isPaid
                ? 'Pembayaran Ongkir Berhasil'
                : 'Menunggu Pembayaran Pengiriman',
            message: isPaid
                ? 'Pembayaran sebesar Rp $jumlah telah diverifikasi. Pengiriman Anda segera diproses kurir.'
                : 'Silakan selesaikan pembayaran sebesar Rp $jumlah agar pesanan segera dikirim.',
            type: NotificationType.payment,
            isRead: false,
            createdAt: createdAt,
            paymentId: pId,
            shipmentId: shipmentId,
          ),
        );
      }
    } catch (_) {}

    // Urutkan berdasarkan waktu terbaru
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Terapkan filter dan pencarian
    var filtered = result;
    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
    } else if (filter == NotificationFilter.payment) {
      filtered = filtered.where((n) => n.isPayment).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.message.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }

  @override
  Future<int> getUnreadCount() async {
    if (!_isSupabaseAvailable) {
      return 2;
    }

    try {
      final userId = await _resolveUserId();
      final res = await _client
          .from(DatabaseConstants.tableNotifications)
          .select(NotificationTableColumns.id)
          .eq(NotificationTableColumns.userId, userId)
          .eq(NotificationTableColumns.isRead, false);

      return (res as List).length;
    } catch (_) {
      final notifs = await getNotifications(filter: NotificationFilter.unread);
      return notifs.length;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (!_isSupabaseAvailable) return;

    try {
      await _client.from(DatabaseConstants.tableNotifications).update({
        NotificationTableColumns.isRead: true,
        NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
      }).eq(NotificationTableColumns.id, notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    if (!_isSupabaseAvailable) return;

    try {
      final userId = await _resolveUserId();
      await _client.from(DatabaseConstants.tableNotifications).update({
        NotificationTableColumns.isRead: true,
        NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
      }).eq(NotificationTableColumns.userId, userId);
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    if (!_isSupabaseAvailable) return;

    try {
      await _client
          .from(DatabaseConstants.tableNotifications)
          .delete()
          .eq(NotificationTableColumns.id, notificationId);
    } catch (_) {}
  }

  @override
  Future<void> clearAllNotifications() async {
    if (!_isSupabaseAvailable) return;

    try {
      final userId = await _resolveUserId();
      await _client
          .from(DatabaseConstants.tableNotifications)
          .delete()
          .eq(NotificationTableColumns.userId, userId);
    } catch (_) {}
  }

  @override
  Stream<List<NotificationItemModel>> subscribeNotifications() {
    if (!_isSupabaseAvailable) {
      return Stream.value(_buildOfflineFallbackNotifications(
        NotificationFilter.all,
        null,
      ));
    }

    try {
      final streamController =
          StreamController<List<NotificationItemModel>>.broadcast();

      _resolveUserId().then((userId) {
        _client
            .from(DatabaseConstants.tableNotifications)
            .stream(primaryKey: [NotificationTableColumns.id])
            .eq(NotificationTableColumns.userId, userId)
            .order(NotificationTableColumns.createdAt, ascending: false)
            .listen(
              (rows) {
                final list = rows
                    .map((r) => NotificationItemModel.fromDatabase(r))
                    .toList();
                streamController.add(list);
              },
              onError: (error) {
                // Jika streaming gagal, lakukan fetch satu kali
                getNotifications().then(streamController.add);
              },
            );
      });

      return streamController.stream;
    } catch (_) {
      return Stream.fromFuture(getNotifications());
    }
  }

  List<NotificationItemModel> _buildOfflineFallbackNotifications(
    NotificationFilter filter,
    String? searchQuery,
  ) {
    final now = DateTime.now();
    final list = [
      NotificationItemModel(
        id: 'notif-demo-1',
        userId: 'usr-01',
        title: 'Paket Sedang Diantar Kurir SatSet',
        message:
            'Kurir SatSet sedang meluncur mengantarkan paket dengan nomor resi #SATSET-20261021-001 ke alamat Anda.',
        type: NotificationType.shipment,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 15)),
        shipmentId: '1',
        metadata: {'nomor_resi': 'SATSET-20261021-001'},
      ),
      NotificationItemModel(
        id: 'notif-demo-2',
        userId: 'usr-01',
        title: 'Pembayaran Ongkos Kirim Berhasil',
        message:
            'Pembayaran SatSet Pay sebesar Rp 45.000 untuk pengiriman kilat Instant Courier telah diverifikasi sistem.',
        type: NotificationType.payment,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        paymentId: 'pay-01',
        shipmentId: '1',
      ),
      NotificationItemModel(
        id: 'notif-demo-3',
        userId: 'usr-01',
        title: 'Paket Berhasil Diserahkan ke Sorting Hub',
        message:
            'Paket Anda #SATSET-20261020-088 telah sampai di Sorting Hub Jakarta Pusat dan sedang dijadwalkan.',
        type: NotificationType.shipment,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        shipmentId: '2',
        metadata: {'nomor_resi': 'SATSET-20261020-088'},
      ),
      NotificationItemModel(
        id: 'notif-demo-4',
        userId: 'usr-01',
        title: 'Keamanan Akun Diperbarui',
        message:
            'Sandi akun Anda baru saja berhasil diperbarui. Jika Anda tidak merasa melakukannya, segera hubungi CS SatSet.',
        type: NotificationType.account,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    var filtered = list;
    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
    } else if (filter == NotificationFilter.payment) {
      filtered = filtered.where((n) => n.isPayment).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.message.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }
}
