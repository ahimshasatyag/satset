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
    String? userId,
  });

  Future<int> getUnreadCount({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAllNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });
  Future<NotificationItemModel> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? shipmentId,
    bool isCourier = false,
    String? courierId,
    String? userId,
  });
  Stream<List<NotificationItemModel>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
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

  Future<String> _resolveUserId({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    if (courierId != null && courierId.trim().isNotEmpty) {
      return courierId.trim();
    }
    if (userId != null && userId.trim().isNotEmpty) {
      return userId.trim();
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

    // Coba ambil ID pengguna pertama yang ada di m_users Supabase
    if (_isSupabaseAvailable) {
      try {
        final firstUser = await _client
            .from(DatabaseConstants.tableUsers)
            .select(UserTableColumns.id)
            .order(UserTableColumns.id, ascending: true)
            .limit(1)
            .maybeSingle();
        if (firstUser != null && firstUser[UserTableColumns.id] != null) {
          return firstUser[UserTableColumns.id].toString();
        }
      } catch (_) {}
    }

    return '4';
  }

  @override
  Future<List<NotificationItemModel>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    final effectiveUserId = await _resolveUserId(
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );

    if (!_isSupabaseAvailable) {
      return const [];
    }

    try {
      final int? numId = int.tryParse(effectiveUserId);
      var query = _client.from(DatabaseConstants.tableNotifications).select();

      if (isCourier) {
        if (numId != null) {
          query = query.or('employee_id.eq.$numId,employee_id.is.null');
        }
      } else {
        if (numId != null) {
          query = query.or('user_id.eq.$numId,user_id.is.null');
        }
      }

      if (filter == NotificationFilter.unread) {
        query = query.eq(NotificationTableColumns.isRead, false);
      } else if (filter == NotificationFilter.shipment) {
        query = query.or(
            '${NotificationTableColumns.tipe}.eq.STATUS,${NotificationTableColumns.tipe}.eq.shipment');
      } else if (filter == NotificationFilter.payment) {
        query = query.or(
            '${NotificationTableColumns.tipe}.eq.PAYMENT,${NotificationTableColumns.tipe}.eq.payment');
      } else if (filter == NotificationFilter.assignment) {
        query = query.or(
            '${NotificationTableColumns.tipe}.eq.ASSIGNMENT,${NotificationTableColumns.tipe}.eq.assignment');
      } else if (filter == NotificationFilter.urgent) {
        query = query.or(
            '${NotificationTableColumns.tipe}.eq.WARNING,${NotificationTableColumns.tipe}.eq.urgent');
      } else if (filter == NotificationFilter.system) {
        query = query.or(
            '${NotificationTableColumns.tipe}.eq.INFO,${NotificationTableColumns.tipe}.eq.system');
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final cleanSearch = searchQuery.trim();
        query = query.or(
            '${NotificationTableColumns.judul}.ilike.%$cleanSearch%,${NotificationTableColumns.pesan}.ilike.%$cleanSearch%');
      }

      final rows = await query
          .order(NotificationTableColumns.createdAt, ascending: false)
          .range(offset, offset + limit - 1);

      final list = (rows as List)
          .map((r) =>
              NotificationItemModel.fromDatabase(r as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;

      // Jika user belum memiliki baris spesifik di t_notifications,
      // coba ambil notifikasi dari t_notifications Supabase tanpa batasan user
      if (offset == 0) {
        var fallbackQuery =
            _client.from(DatabaseConstants.tableNotifications).select();

        if (filter == NotificationFilter.unread) {
          fallbackQuery =
              fallbackQuery.eq(NotificationTableColumns.isRead, false);
        } else if (filter == NotificationFilter.shipment) {
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.tipe}.eq.STATUS,${NotificationTableColumns.tipe}.eq.shipment');
        } else if (filter == NotificationFilter.payment) {
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.tipe}.eq.PAYMENT,${NotificationTableColumns.tipe}.eq.payment');
        } else if (filter == NotificationFilter.assignment) {
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.tipe}.eq.ASSIGNMENT,${NotificationTableColumns.tipe}.eq.assignment');
        } else if (filter == NotificationFilter.urgent) {
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.tipe}.eq.WARNING,${NotificationTableColumns.tipe}.eq.urgent');
        } else if (filter == NotificationFilter.system) {
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.tipe}.eq.INFO,${NotificationTableColumns.tipe}.eq.system');
        }

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final cleanSearch = searchQuery.trim();
          fallbackQuery = fallbackQuery.or(
              '${NotificationTableColumns.judul}.ilike.%$cleanSearch%,${NotificationTableColumns.pesan}.ilike.%$cleanSearch%');
        }

        final fallbackRows = await fallbackQuery
            .order(NotificationTableColumns.createdAt, ascending: false)
            .limit(limit);

        final fallbackList = (fallbackRows as List)
            .map((r) =>
                NotificationItemModel.fromDatabase(r as Map<String, dynamic>))
            .toList();

        if (fallbackList.isNotEmpty) return fallbackList;
      }

      // Coba sinkronisasi pengiriman aktif ke t_notifications jika belum ada
      if (isCourier) {
        return await _fetchNotificationsFromCourierTasks(
            effectiveUserId, filter, searchQuery);
      } else {
        return await _fetchNotificationsFromShipments(
            effectiveUserId, filter, searchQuery);
      }
    } catch (_) {
      try {
        if (isCourier) {
          return await _fetchNotificationsFromCourierTasks(
              effectiveUserId, filter, searchQuery);
        } else {
          return await _fetchNotificationsFromShipments(
              effectiveUserId, filter, searchQuery);
        }
      } catch (_) {
        return const [];
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

      if (_isSupabaseAvailable && result.isNotEmpty) {
        final numCourierId = int.tryParse(courierId);
        if (numCourierId != null) {
          try {
            final payloads = result.map((n) {
              final sIdInt =
                  n.shipmentId != null ? int.tryParse(n.shipmentId!) : null;
              return {
                NotificationTableColumns.employeeId: numCourierId,
                NotificationTableColumns.shipmentId: ?sIdInt,
                NotificationTableColumns.judul: n.title,
                NotificationTableColumns.pesan: n.message,
                NotificationTableColumns.tipe:
                    n.isUrgent ? 'WARNING' : 'ASSIGNMENT',
                NotificationTableColumns.isRead: n.isRead,
                NotificationTableColumns.createdAt:
                    n.createdAt.toIso8601String(),
              };
            }).toList();

            final inserted = await _client
                .from(DatabaseConstants.tableNotifications)
                .insert(payloads)
                .select();

            final insertedModels = (inserted as List)
                .map((r) => NotificationItemModel.fromDatabase(
                    r as Map<String, dynamic>))
                .toList();

            if (insertedModels.isNotEmpty) {
              result.clear();
              result.addAll(insertedModels);
            }
          } catch (_) {}
        }
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

      if (_isSupabaseAvailable && result.isNotEmpty) {
        final numUserId = int.tryParse(userId);
        if (numUserId != null) {
          try {
            final payloads = result.map((n) {
              final sIdInt =
                  n.shipmentId != null ? int.tryParse(n.shipmentId!) : null;
              return {
                NotificationTableColumns.userId: numUserId,
                NotificationTableColumns.shipmentId: ?sIdInt,
                NotificationTableColumns.judul: n.title,
                NotificationTableColumns.pesan: n.message,
                NotificationTableColumns.tipe: 'STATUS',
                NotificationTableColumns.isRead: n.isRead,
                NotificationTableColumns.createdAt:
                    n.createdAt.toIso8601String(),
              };
            }).toList();

            final inserted = await _client
                .from(DatabaseConstants.tableNotifications)
                .insert(payloads)
                .select();

            final insertedModels = (inserted as List)
                .map((r) => NotificationItemModel.fromDatabase(
                    r as Map<String, dynamic>))
                .toList();

            if (insertedModels.isNotEmpty) {
              result.clear();
              result.addAll(insertedModels);
            }
          } catch (_) {}
        }
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
  Future<int> getUnreadCount({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    final list = await getNotifications(
      filter: NotificationFilter.unread,
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
    return list.length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (!_isSupabaseAvailable) return;
    try {
      final int? numId = int.tryParse(notificationId);
      final query = _client.from(DatabaseConstants.tableNotifications).update({
        NotificationTableColumns.isRead: true,
        NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
      });
      if (numId != null) {
        await query.eq(NotificationTableColumns.id, numId);
      } else {
        await query.eq(NotificationTableColumns.id, notificationId);
      }
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    if (!_isSupabaseAvailable) return;
    try {
      final effectiveUserId = await _resolveUserId(
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );
      final int? numId = int.tryParse(effectiveUserId);

      var query = _client
          .from(DatabaseConstants.tableNotifications)
          .update({
            NotificationTableColumns.isRead: true,
            NotificationTableColumns.readAt: DateTime.now().toIso8601String(),
          })
          .eq(NotificationTableColumns.isRead, false);

      if (isCourier && numId != null) {
        await query.or('employee_id.eq.$numId,user_id.eq.$numId');
      } else if (numId != null) {
        await query.eq(NotificationTableColumns.userId, numId);
      } else {
        await query.eq(NotificationTableColumns.userId, effectiveUserId);
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    if (!_isSupabaseAvailable) return;
    try {
      final int? numId = int.tryParse(notificationId);
      final query = _client.from(DatabaseConstants.tableNotifications).delete();
      if (numId != null) {
        await query.eq(NotificationTableColumns.id, numId);
      } else {
        await query.eq(NotificationTableColumns.id, notificationId);
      }
    } catch (_) {}
  }

  @override
  Future<void> clearAllNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    if (!_isSupabaseAvailable) return;
    try {
      final effectiveUserId = await _resolveUserId(
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );
      final int? numId = int.tryParse(effectiveUserId);
      final query = _client.from(DatabaseConstants.tableNotifications).delete();

      if (isCourier && numId != null) {
        await query.or('employee_id.eq.$numId,user_id.eq.$numId');
      } else if (numId != null) {
        await query.eq(NotificationTableColumns.userId, numId);
      } else {
        await query.eq(NotificationTableColumns.userId, effectiveUserId);
      }
    } catch (_) {}
  }

  @override
  Future<NotificationItemModel> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? shipmentId,
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    final effectiveUserId = await _resolveUserId(
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );
    final int? numUserId = int.tryParse(effectiveUserId);
    final int? numShipmentId =
        shipmentId != null ? int.tryParse(shipmentId) : null;

    String dbType;
    switch (type) {
      case NotificationType.shipment:
        dbType = 'STATUS';
        break;
      case NotificationType.payment:
        dbType = 'PAYMENT';
        break;
      case NotificationType.taskAssignment:
        dbType = 'ASSIGNMENT';
        break;
      case NotificationType.urgentTask:
        dbType = 'WARNING';
        break;
      case NotificationType.system:
      case NotificationType.account:
      case NotificationType.promo:
        dbType = 'INFO';
        break;
    }

    if (!_isSupabaseAvailable) {
      final now = DateTime.now();
      return NotificationItemModel(
        id: 'local-${now.millisecondsSinceEpoch}',
        userId: effectiveUserId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: now,
        shipmentId: shipmentId,
      );
    }

    try {
      final payload = <String, dynamic>{
        NotificationTableColumns.judul: title,
        NotificationTableColumns.pesan: message,
        NotificationTableColumns.tipe: dbType,
        NotificationTableColumns.isRead: false,
        (isCourier
            ? NotificationTableColumns.employeeId
            : NotificationTableColumns.userId): ?numUserId,
        NotificationTableColumns.shipmentId: ?numShipmentId,
      };

      final row = await _client
          .from(DatabaseConstants.tableNotifications)
          .insert(payload)
          .select()
          .single();

      return NotificationItemModel.fromDatabase(row);
    } catch (e) {
      final now = DateTime.now();
      return NotificationItemModel(
        id: 'local-${now.millisecondsSinceEpoch}',
        userId: effectiveUserId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: now,
        shipmentId: shipmentId,
      );
    }
  }

  @override
  Stream<List<NotificationItemModel>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    late StreamController<List<NotificationItemModel>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<NotificationItemModel>>.broadcast(
      onListen: () async {
        final initial = await getNotifications(
          isCourier: isCourier,
          courierId: courierId,
          userId: userId,
        );
        if (!controller.isClosed) controller.add(initial);

        if (_isSupabaseAvailable) {
          channel = _client.channel('public:t_notifications_all');
          channel!
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: DatabaseConstants.tableNotifications,
                callback: (_) async {
                  final updated = await getNotifications(
                    isCourier: isCourier,
                    courierId: courierId,
                    userId: userId,
                  );
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
}
