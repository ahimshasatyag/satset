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
    bool isCourier = false,
    String? courierId,
  });

  Future<int> getUnreadCount({bool isCourier = false, String? courierId});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead({bool isCourier = false, String? courierId});
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAllNotifications({bool isCourier = false, String? courierId});
  Stream<List<NotificationItemModel>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? authLocalDataSource;

  NotificationRemoteDataSourceImpl({
    SupabaseClient? client,
    this.authLocalDataSource,
  }) : _customClient = client;

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

  Future<String> _resolveUserId({bool isCourier = false, String? courierId}) async {
    if (courierId != null && courierId.trim().isNotEmpty) {
      return courierId.trim();
    }

    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        final email = (authUser.email ?? '').trim().toLowerCase();

        // 1. Jika mode kurir atau email kurir, cari di m_employee
        if (isCourier || email.isNotEmpty) {
          try {
            final empRes = await _client
                .from(DatabaseConstants.tableEmployee)
                .select(DatabaseConstants.colId)
                .or('email.eq.$email,user_id.eq.${authUser.id}')
                .maybeSingle();

            if (empRes != null && empRes[DatabaseConstants.colId] != null) {
              return empRes[DatabaseConstants.colId].toString();
            }
          } catch (_) {}
        }

        // 2. Jika bukan kurir, cari di m_users
        if (!isCourier && email.isNotEmpty) {
          try {
            final res = await _client
                .from(DatabaseConstants.tableUsers)
                .select(UserTableColumns.id)
                .eq(UserTableColumns.email, email)
                .maybeSingle();

            if (res != null && res[UserTableColumns.id] != null) {
              return res[UserTableColumns.id].toString();
            }
          } catch (_) {}
        }
      }
    }

    try {
      final localUser =
          await (authLocalDataSource ?? AuthLocalDataSourceImpl()).getUser();
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
    bool isCourier = false,
    String? courierId,
  }) async {
    final userId = await _resolveUserId(isCourier: isCourier, courierId: courierId);

    if (!_isSupabaseAvailable) {
      if (isCourier) {
        return _buildOfflineFallbackCourierNotifications(filter, searchQuery);
      }
      return _buildOfflineFallbackNotifications(filter, searchQuery);
    }

    try {
      var query = _client
          .from(DatabaseConstants.tableNotifications)
          .select()
          .eq(NotificationTableColumns.userId, userId);

      if (filter == NotificationFilter.unread) {
        query = query.eq(NotificationTableColumns.isRead, false);
      } else if (filter == NotificationFilter.shipment) {
        query = query.or('${NotificationTableColumns.type}.eq.shipment,${NotificationTableColumns.type}.eq.pengiriman');
      } else if (filter == NotificationFilter.payment) {
        query = query.eq(NotificationTableColumns.type, 'payment');
      } else if (filter == NotificationFilter.assignment) {
        query = query.or('${NotificationTableColumns.type}.eq.assignment,${NotificationTableColumns.type}.eq.task_assignment');
      } else if (filter == NotificationFilter.urgent) {
        query = query.or('${NotificationTableColumns.type}.eq.urgent,${NotificationTableColumns.type}.eq.urgent_task');
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

      // Jika tabel t_notifications belum memiliki baris untuk kurir/pelanggan,
      // bangun notifikasi dinamis dari data tugas atau pengiriman nyata
      if (isCourier) {
        return await _fetchNotificationsFromCourierTasks(userId, filter, searchQuery);
      } else {
        return await _fetchNotificationsFromShipments(userId, filter, searchQuery);
      }
    } catch (_) {
      try {
        if (isCourier) {
          return await _fetchNotificationsFromCourierTasks(userId, filter, searchQuery);
        } else {
          return await _fetchNotificationsFromShipments(userId, filter, searchQuery);
        }
      } catch (_) {
        if (isCourier) {
          return _buildOfflineFallbackCourierNotifications(filter, searchQuery);
        }
        return _buildOfflineFallbackNotifications(filter, searchQuery);
      }
    }
  }

  /// Menghasilkan notifikasi dinamis kurir dari t_shipment_assignments dan t_shipments
  Future<List<NotificationItemModel>> _fetchNotificationsFromCourierTasks(
    String courierId,
    NotificationFilter filter,
    String? searchQuery,
  ) async {
    final List<NotificationItemModel> result = [];

    try {
      final assignmentRows = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select('''
            *,
            ${DatabaseConstants.tableShipments}(*, ${DatabaseConstants.tableShipmentStatuses}(*))
          ''')
          .eq(ShipmentAssignmentTableColumns.courierId, courierId)
          .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
          .limit(20);

      for (final a in assignmentRows as List) {
        final aMap = a as Map<String, dynamic>;
        final shipmentMap = (aMap['t_shipments'] is Map<String, dynamic>)
            ? aMap['t_shipments'] as Map<String, dynamic>
            : null;

        if (shipmentMap == null) continue;

        final statusMap = (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>)
            ? shipmentMap['m_shipment_statuses'] as Map<String, dynamic>
            : null;

        final shipmentId = shipmentMap[ShipmentTableColumns.id]?.toString() ?? '';
        final resi = shipmentMap[ShipmentTableColumns.nomorResi]?.toString() ?? '-';
        final statusCode = statusMap?['kode']?.toString() ?? 'PENDING';
        final pengirim = shipmentMap[ShipmentTableColumns.pengirimNama]?.toString() ?? 'Pengirim';
        final penerima = shipmentMap[ShipmentTableColumns.penerimaNama]?.toString() ?? 'Penerima';
        final alamatPengirim = shipmentMap[ShipmentTableColumns.pengirimAlamat]?.toString() ?? '-';
        final alamatPenerima = shipmentMap[ShipmentTableColumns.penerimaAlamat]?.toString() ?? '-';
        final assignedAtStr = aMap[ShipmentAssignmentTableColumns.assignedAt]?.toString();
        final assignedAt = assignedAtStr != null
            ? DateTime.tryParse(assignedAtStr) ?? DateTime.now()
            : DateTime.now();

        NotificationType type = NotificationType.taskAssignment;
        String title;
        String message;

        switch (statusCode.toUpperCase()) {
          case 'PICKUP_SCHEDULED':
          case 'PENDING':
          case 'CONFIRMED':
            title = 'Tugas Pickup Baru';
            message = 'Jemput paket resi #$resi dari $pengirim ($alamatPengirim)';
            type = NotificationType.taskAssignment;
            break;
          case 'PICKED_UP':
          case 'IN_TRANSIT':
            title = 'Paket Dalam Pengiriman';
            message = 'Paket resi #$resi sedang dalam perjalanan menuju hub atau penerima.';
            type = NotificationType.shipment;
            break;
          case 'OUT_FOR_DELIVERY':
            title = 'Mulai Antar ke Penerima';
            message = 'Antar paket resi #$resi ke $penerima ($alamatPenerima).';
            type = NotificationType.urgentTask;
            break;
          case 'DELIVERED':
            title = 'Tugas Pengantaran Selesai';
            message = 'Paket resi #$resi telah berhasil diserahkan kepada $penerima.';
            type = NotificationType.shipment;
            break;
          case 'FAILED_DELIVERY':
            title = 'Pengantaran Gagal Dilaporkan';
            message = 'Laporan gagal kirim paket resi #$resi telah disimpan.';
            type = NotificationType.urgentTask;
            break;
          default:
            title = 'Pembaruan Tugas Kurir';
            message = 'Tugas pengiriman #$resi berstatus: $statusCode.';
            type = NotificationType.taskAssignment;
        }

        result.add(
          NotificationItemModel(
            id: 'notif-assignment-${aMap['id']}',
            userId: courierId,
            title: title,
            message: message,
            type: type,
            isRead: aMap[ShipmentAssignmentTableColumns.completedAt] != null,
            createdAt: assignedAt,
            shipmentId: shipmentId,
            metadata: {
              'nomor_resi': resi,
              'status_code': statusCode,
              'pengirim': pengirim,
              'penerima': penerima,
            },
          ),
        );
      }
    } catch (_) {}

    var filtered = result;
    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.assignment) {
      filtered = filtered.where((n) => n.isAssignment).toList();
    } else if (filter == NotificationFilter.urgent) {
      filtered = filtered.where((n) => n.isUrgent).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.message.toLowerCase().contains(q) ||
              (n.metadata?['nomor_resi']?.toString().toLowerCase().contains(q) ?? false))
          .toList();
    }

    return filtered;
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
            message = 'Pesanan pengiriman ke $penerima (Resi: $resi) berhasil dibuat.';
            break;
          case '2':
            title = 'Pengiriman Dikonfirmasi';
            message = 'Paket Anda #$resi telah dikonfirmasi dan menunggu kurir SatSet.';
            break;
          case '4':
          case '5':
            title = 'Paket Dalam Perjalanan';
            message = 'Paket #$resi sedang dalam perjalanan bersama kurir SatSet.';
            break;
          case '7':
            title = 'Kurir Menuju Alamat Anda';
            message = 'Kurir SatSet sedang meluncur mengantarkan paket #$resi ke lokasi penerima.';
            break;
          case '8':
            title = 'Paket Berhasil Diterima';
            message = 'Paket #$resi telah berhasil diserahkan kepada penerima. Terima kasih!';
            break;
          case '9':
            title = 'Pengantaran Ditunda / Gagal';
            message = 'Kurir belum berhasil menyerahkan paket #$resi. Akan dijadwalkan ulang.';
            break;
          default:
            title = 'Status Pengiriman Diperbarui';
            message = 'Pembaruan status untuk paket pengiriman #$resi.';
        }

        result.add(
          NotificationItemModel(
            id: 'notif-shipment-$shipmentId',
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.shipment,
            isRead: statusId == '8',
            createdAt: createdAt,
            shipmentId: shipmentId,
            metadata: {'nomor_resi': resi},
          ),
        );
      }
    } catch (_) {}

    var filtered = result;
    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
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
  Future<int> getUnreadCount({bool isCourier = false, String? courierId}) async {
    final list = await getNotifications(
      filter: NotificationFilter.unread,
      isCourier: isCourier,
      courierId: courierId,
    );
    return list.length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (!_isSupabaseAvailable) return;
    try {
      await _client
          .from(DatabaseConstants.tableNotifications)
          .update({
            NotificationTableColumns.isRead: true,
            NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
          })
          .eq(NotificationTableColumns.id, notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead({bool isCourier = false, String? courierId}) async {
    if (!_isSupabaseAvailable) return;
    try {
      final userId = await _resolveUserId(isCourier: isCourier, courierId: courierId);
      await _client
          .from(DatabaseConstants.tableNotifications)
          .update({
            NotificationTableColumns.isRead: true,
            NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
          })
          .eq(NotificationTableColumns.userId, userId)
          .eq(NotificationTableColumns.isRead, false);
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
  Future<void> clearAllNotifications({bool isCourier = false, String? courierId}) async {
    if (!_isSupabaseAvailable) return;
    try {
      final userId = await _resolveUserId(isCourier: isCourier, courierId: courierId);
      await _client
          .from(DatabaseConstants.tableNotifications)
          .delete()
          .eq(NotificationTableColumns.userId, userId);
    } catch (_) {}
  }

  @override
  Stream<List<NotificationItemModel>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
  }) {
    late StreamController<List<NotificationItemModel>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<NotificationItemModel>>.broadcast(
      onListen: () async {
        final userId = await _resolveUserId(isCourier: isCourier, courierId: courierId);
        final initial = await getNotifications(isCourier: isCourier, courierId: courierId);
        if (!controller.isClosed) controller.add(initial);

        if (_isSupabaseAvailable) {
          channel = _client.channel('public:t_notifications:$userId');
          channel!
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: DatabaseConstants.tableNotifications,
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: NotificationTableColumns.userId,
                  value: userId,
                ),
                callback: (_) async {
                  final updated = await getNotifications(isCourier: isCourier, courierId: courierId);
                  if (!controller.isClosed) controller.add(updated);
                },
              )
              .subscribe();
        }
      },
      onCancel: () {
        if (channel != null && _isSupabaseAvailable) {
          _client.removeChannel(channel!);
          channel = null;
        }
      },
    );

    return controller.stream;
  }

  List<NotificationItemModel> _buildOfflineFallbackCourierNotifications(
    NotificationFilter filter,
    String? searchQuery,
  ) {
    final now = DateTime.now();
    final list = [
      NotificationItemModel(
        id: 'courier-notif-1',
        userId: 'emp-courier-01',
        title: 'Tugas Penjemputan Baru',
        message: 'Anda ditugaskan menjemput paket #SATSET-20261026-001 dari Toko Berkah Mandiri.',
        type: NotificationType.taskAssignment,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 10)),
        shipmentId: '1',
        metadata: {'nomor_resi': 'SATSET-20261026-001'},
      ),
      NotificationItemModel(
        id: 'courier-notif-2',
        userId: 'emp-courier-01',
        title: 'Pengantaran Prioritas Tinggi',
        message: 'Paket #SATSET-20261026-002 memerlukan pengantaran segera sebelum jam 17:00 WIB.',
        type: NotificationType.urgentTask,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
        shipmentId: '2',
        metadata: {'nomor_resi': 'SATSET-20261026-002'},
      ),
      NotificationItemModel(
        id: 'courier-notif-3',
        userId: 'emp-courier-01',
        title: 'Pengantaran Berhasil Diverifikasi',
        message: 'Bukti serah terima untuk resi #SATSET-20261025-099 berhasil disetujui hub operasional.',
        type: NotificationType.shipment,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        shipmentId: '3',
        metadata: {'nomor_resi': 'SATSET-20261025-099'},
      ),
      NotificationItemModel(
        id: 'courier-notif-4',
        userId: 'emp-courier-01',
        title: 'Pengumuman Operasional SatSet',
        message: 'Pembaruan rute pengantaran area Jakarta Pusat berlaku mulai besok pagi.',
        type: NotificationType.system,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    var filtered = list;
    if (filter == NotificationFilter.unread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (filter == NotificationFilter.assignment) {
      filtered = filtered.where((n) => n.isAssignment).toList();
    } else if (filter == NotificationFilter.urgent) {
      filtered = filtered.where((n) => n.isUrgent).toList();
    } else if (filter == NotificationFilter.shipment) {
      filtered = filtered.where((n) => n.isShipment).toList();
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
