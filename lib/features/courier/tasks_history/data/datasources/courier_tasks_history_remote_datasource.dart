import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/entities/courier_task_history_stats.dart';
import '../models/courier_task_history_item_model.dart';
import '../models/shipment_proof_history_item_model.dart';
import '../models/shipment_tracking_history_item_model.dart';

abstract class CourierTasksHistoryRemoteDataSource {
  /// Mengambil daftar riwayat tugas kurir yang tersimpan di database
  Future<List<CourierTaskHistoryItemModel>> getHistoryTasks({
    String? courierId,
    CourierHistoryTaskType? taskType,
    String? statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  /// Mengambil catatan jejak kronologis pelacakan dari t_shipment_tracking
  Future<List<ShipmentTrackingHistoryItemModel>> getTrackingTimeline({
    required String shipmentId,
  });

  /// Mengambil bukti serah terima / pengiriman dari t_shipment_proofs
  Future<List<ShipmentProofHistoryItemModel>> getShipmentProofs({
    required String shipmentId,
    String? courierId,
  });

  /// Menghitung ringkasan statistik riwayat tugas kurir
  Future<CourierTaskHistoryStats> getHistoryStats({String? courierId});

  /// Menyelesaikan ID kurir aktif yang sedang login
  Future<String> resolveCourierId({String? overrideId});
}

class CourierTasksHistoryRemoteDataSourceImpl
    implements CourierTasksHistoryRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  CourierTasksHistoryRemoteDataSourceImpl({
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
    this.currentUser,
  })  : _customClient = client,
        _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSourceImpl();

  bool get _isSupabaseAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  @override
  Future<String> resolveCourierId({String? overrideId}) async {
    if (overrideId != null && overrideId.trim().isNotEmpty) {
      return overrideId.trim();
    }

    if (currentUser != null && currentUser!.id.isNotEmpty) {
      return currentUser!.id;
    }

    try {
      final savedUser = await _authLocalDataSource?.getUser();
      if (savedUser != null && savedUser.id.isNotEmpty) {
        return savedUser.id;
      }
    } catch (_) {}

    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        final email = (authUser.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          // 1. Cari kurir di m_employee berdasarkan email atau user_id
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

          // 2. Fallback cek di m_users
          try {
            final res = await _client
                .from(DatabaseConstants.tableUsers)
                .select(DatabaseConstants.colId)
                .eq(DatabaseConstants.colEmail, email)
                .maybeSingle();

            if (res != null && res[DatabaseConstants.colId] != null) {
              return res[DatabaseConstants.colId].toString();
            }
          } catch (_) {}
        }
        return authUser.id;
      }

      // 3. Fallback ambil kurir pertama dari m_employee jika ada
      try {
        final firstEmp = await _client
            .from(DatabaseConstants.tableEmployee)
            .select(DatabaseConstants.colId)
            .limit(1)
            .maybeSingle();
        if (firstEmp != null && firstEmp[DatabaseConstants.colId] != null) {
          return firstEmp[DatabaseConstants.colId].toString();
        }
      } catch (_) {}
    }

    return '6';
  }

  @override
  Future<List<CourierTaskHistoryItemModel>> getHistoryTasks({
    String? courierId,
    CourierHistoryTaskType? taskType,
    String? statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_isSupabaseAvailable) {
      return [];
    }

    final activeCourierId = await resolveCourierId(overrideId: courierId);

    try {
      final fromIndex = (page - 1) * limit;
      final toIndex = fromIndex + limit - 1;
      dynamic rows = [];

      // Query penugasan kurir dari t_shipment_assignments dengan join relasi t_shipments,
      // m_shipment_statuses, dan m_service_types
      try {
        var query = _client.from(DatabaseConstants.tableShipmentAssignments).select('''
          *,
          ${DatabaseConstants.tableShipments}(
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*)
          )
        ''');

        // Terapkan Row Level Security / filter kurir yang sedang login
        if (activeCourierId.isNotEmpty) {
          final parsedInt = int.tryParse(activeCourierId);
          if (parsedInt != null) {
            query = query.eq(ShipmentAssignmentTableColumns.courierId, parsedInt);
          } else {
            query = query.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
          }
        }

        // Urutkan riwayat dari yang terbaru ke yang terlama berdasarkan waktu penugasan/penyelesaian
        rows = await query
            .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
            .range(fromIndex, toIndex);
      } catch (_) {
        // Fallback jika relasi nested gagal: query tanpa relasi bertingkat
        try {
          var fallbackQuery = _client
              .from(DatabaseConstants.tableShipmentAssignments)
              .select('''
                *,
                ${DatabaseConstants.tableShipments}(*)
              ''');

          if (activeCourierId.isNotEmpty) {
            final parsedInt = int.tryParse(activeCourierId);
            if (parsedInt != null) {
              fallbackQuery = fallbackQuery.eq(
                  ShipmentAssignmentTableColumns.courierId, parsedInt);
            } else {
              fallbackQuery = fallbackQuery.eq(
                  ShipmentAssignmentTableColumns.courierId, activeCourierId);
            }
          }

          rows = await fallbackQuery
              .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
              .range(fromIndex, toIndex);
        } catch (_) {
          rows = [];
        }
      }

      List<CourierTaskHistoryItemModel> list = (rows as List)
          .map<CourierTaskHistoryItemModel>((r) =>
              CourierTaskHistoryItemModel.fromDatabase(
                r as Map<String, dynamic>,
                currentCourierId: activeCourierId,
              ))
          .toList();

      // Filter Jenis Tugas (Pickup vs Delivery)
      if (taskType != null && taskType != CourierHistoryTaskType.all) {
        list = list.where((task) => task.taskType == taskType).toList();
      }

      // Filter Status Riwayat (DELIVERED, FAILED_DELIVERY, RETURNED, CANCELLED)
      if (statusCode != null &&
          statusCode.trim().isNotEmpty &&
          statusCode.toUpperCase() != 'ALL') {
        final cleanStatus = statusCode.trim().toUpperCase();
        list = list
            .where((task) => task.statusCode.toUpperCase() == cleanStatus)
            .toList();
      }

      // Filter Rentang Tanggal
      if (startDate != null) {
        final startDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        list = list.where((task) {
          final t = task.primaryCompletionTime;
          return t.isAfter(startDay) || t.isAtSameMomentAs(startDay);
        }).toList();
      }

      if (endDate != null) {
        final endDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        list = list.where((task) {
          final t = task.primaryCompletionTime;
          return t.isBefore(endDay) || t.isAtSameMomentAs(endDay);
        }).toList();
      }

      // Filter Pencarian Teks Dinamis (nomor resi atau nama penerima/pengirim)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((task) {
          return task.trackingNumber.toLowerCase().contains(q) ||
              task.barcodeValue.toLowerCase().contains(q) ||
              task.receiverName.toLowerCase().contains(q) ||
              task.senderName.toLowerCase().contains(q) ||
              task.targetAddress.toLowerCase().contains(q);
        }).toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ShipmentTrackingHistoryItemModel>> getTrackingTimeline({
    required String shipmentId,
  }) async {
    if (!_isSupabaseAvailable) return [];

    try {
      final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
      dynamic rows = [];

      try {
        rows = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('''
              *,
              ${DatabaseConstants.tableShipmentStatuses}(*)
            ''')
            .eq(ShipmentTrackingTableColumns.shipmentId, parsedShipmentId)
            .order(ShipmentTrackingTableColumns.createdAt, ascending: false);
      } catch (_) {
        rows = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('*')
            .eq(ShipmentTrackingTableColumns.shipmentId, parsedShipmentId)
            .order(ShipmentTrackingTableColumns.createdAt, ascending: false);
      }

      return (rows as List)
          .map<ShipmentTrackingHistoryItemModel>((r) =>
              ShipmentTrackingHistoryItemModel.fromDatabase(
                  r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ShipmentProofHistoryItemModel>> getShipmentProofs({
    required String shipmentId,
    String? courierId,
  }) async {
    if (!_isSupabaseAvailable) return [];

    try {
      final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
      var query = _client
          .from(DatabaseConstants.tableShipmentProofs)
          .select('*')
          .eq(ShipmentProofTableColumns.shipmentId, parsedShipmentId);

      // Pastikan otorisasi kurir dipatuhi jika diinstruksikan
      if (courierId != null && courierId.trim().isNotEmpty) {
        final parsedCourierId = int.tryParse(courierId) ?? courierId;
        query = query.eq(ShipmentProofTableColumns.courierId, parsedCourierId);
      }

      final rows = await query.order(ShipmentProofTableColumns.createdAt,
          ascending: false);

      return (rows as List)
          .map<ShipmentProofHistoryItemModel>((r) =>
              ShipmentProofHistoryItemModel.fromDatabase(
                  r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<CourierTaskHistoryStats> getHistoryStats({String? courierId}) async {
    if (!_isSupabaseAvailable) {
      return const CourierTaskHistoryStats();
    }

    try {
      final activeCourierId = await resolveCourierId(overrideId: courierId);
      final parsedCourierId = int.tryParse(activeCourierId) ?? activeCourierId;

      final rows = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select('''
            id,
            status,
            ${DatabaseConstants.tableShipments}(
              id,
              status_id,
              ${DatabaseConstants.tableShipmentStatuses}(kode)
            )
          ''')
          .eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId);

      int total = 0;
      int completed = 0;
      int failed = 0;
      int returned = 0;
      int cancelled = 0;

      for (final r in (rows as List)) {
        total++;
        final shipmentMap = (r['t_shipments'] is Map<String, dynamic>)
            ? r['t_shipments'] as Map<String, dynamic>
            : null;
        final statusMap = (shipmentMap?['m_shipment_statuses']
                is Map<String, dynamic>)
            ? shipmentMap!['m_shipment_statuses'] as Map<String, dynamic>
            : null;

        final code = statusMap?['kode']?.toString().toUpperCase() ??
            (shipmentMap?['status_id'] == 8 ? 'DELIVERED' : '');

        if (code == 'DELIVERED') {
          completed++;
        } else if (code == 'FAILED_DELIVERY') {
          failed++;
        } else if (code == 'RETURNED') {
          returned++;
        } else if (code == 'CANCELLED') {
          cancelled++;
        }
      }

      return CourierTaskHistoryStats(
        totalCount: total,
        completedCount: completed,
        failedCount: failed,
        returnedCount: returned,
        cancelledCount: cancelled,
      );
    } catch (_) {
      return const CourierTaskHistoryStats();
    }
  }
}
