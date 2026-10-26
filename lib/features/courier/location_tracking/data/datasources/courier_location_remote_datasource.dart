import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../models/courier_location_model.dart';
import '../models/courier_tracking_task_model.dart';

abstract class CourierLocationRemoteDataSource {
  /// Mengambil daftar tugas penjemputan/pengantaran aktif milik kurir
  Future<List<CourierTrackingTaskModel>> getActiveCourierTasks({
    String? courierId,
  });

  /// Mengirimkan entri koordinat lokasi kurir ke tabel t_shipment_locations
  Future<void> sendLocationUpdate({
    required String shipmentId,
    required String courierId,
    required CourierLocationModel location,
  });

  /// Mengambil riwayat posisi terakhir yang tercatat di t_shipment_locations
  Future<CourierLocationModel?> getLatestSavedLocation({
    required String shipmentId,
  });

  /// Menyelesaikan ID kurir aktif dari autentikasi
  Future<String> resolveCourierId({String? overrideId});
}

class CourierLocationRemoteDataSourceImpl
    implements CourierLocationRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  CourierLocationRemoteDataSourceImpl({
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
          // Cari di m_employee berdasarkan email atau user_id
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

          // Fallback ke m_users
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
  Future<List<CourierTrackingTaskModel>> getActiveCourierTasks({
    String? courierId,
  }) async {
    if (!_isSupabaseAvailable) return [];

    final activeCourierId = await resolveCourierId(overrideId: courierId);

    try {
      dynamic rows = [];
      final parsedCourierId = int.tryParse(activeCourierId) ?? activeCourierId;

      try {
        var query = _client.from(DatabaseConstants.tableShipmentAssignments).select('''
          *,
          ${DatabaseConstants.tableShipments}(
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*)
          )
        ''');

        if (parsedCourierId is int) {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId);
        } else {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
        }

        // Hanya tugas yang belum diselesaikan
        rows = await query
            .isFilter(ShipmentAssignmentTableColumns.completedAt, null)
            .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false);
      } catch (_) {
        // Fallback jika relasi nested gagal
        try {
          var fallbackQuery = _client
              .from(DatabaseConstants.tableShipmentAssignments)
              .select('''
                *,
                ${DatabaseConstants.tableShipments}(*)
              ''');

          if (parsedCourierId is int) {
            fallbackQuery = fallbackQuery.eq(
                ShipmentAssignmentTableColumns.courierId, parsedCourierId);
          } else {
            fallbackQuery = fallbackQuery.eq(
                ShipmentAssignmentTableColumns.courierId, activeCourierId);
          }

          rows = await fallbackQuery
              .isFilter(ShipmentAssignmentTableColumns.completedAt, null)
              .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false);
        } catch (_) {
          rows = [];
        }
      }

      // Filter hanya status aktif (3 sampai 7, atau status belum selesai 8)
      final tasks = (rows as List)
          .map<CourierTrackingTaskModel>((r) =>
              CourierTrackingTaskModel.fromDatabase(
                r as Map<String, dynamic>,
                currentCourierId: activeCourierId,
              ))
          .where((t) =>
              t.statusId != 8 &&
              t.statusId != 10 &&
              t.statusId != 11 &&
              t.statusCode != 'DELIVERED' &&
              t.statusCode != 'RETURNED' &&
              t.statusCode != 'CANCELLED')
          .toList();

      return tasks;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> sendLocationUpdate({
    required String shipmentId,
    required String courierId,
    required CourierLocationModel location,
  }) async {
    if (!_isSupabaseAvailable) return;

    final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
    final parsedCourierId = int.tryParse(courierId) ?? courierId;

    try {
      // 1. Simpan riwayat koordinat ke t_shipment_locations
      final insertData = <String, dynamic>{
        'shipment_id': parsedShipmentId,
        'courier_id': parsedCourierId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'speed_mps': location.speed ?? 0.0,
        'heading': location.heading ?? 0.0,
        'accuracy_m': location.accuracy ?? 0.0,
        'recorded_at': location.timestamp.toUtc().toIso8601String(),
      };

      await _client
          .from(DatabaseConstants.tableShipmentLocations)
          .insert(insertData);

      // 2. Publikasikan pembaruan lokasi langsung via broadcast channel Realtime Supabase
      try {
        final channel = _client.channel('shipment_live_$shipmentId');
        await channel.sendBroadcastMessage(
          event: 'location_update',
          payload: {
            'shipment_id': shipmentId,
            'courier_id': courierId,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'heading': location.heading ?? 0.0,
            'speed': location.speed ?? 0.0,
            'accuracy': location.accuracy ?? 0.0,
            'timestamp': location.timestamp.toIso8601String(),
          },
        );
      } catch (_) {
        // Broadcast opsional jika channel belum tersubscribe
      }
    } catch (e) {
      throw Exception('Gagal menyimpan pembaruan lokasi kurir: $e');
    }
  }

  @override
  Future<CourierLocationModel?> getLatestSavedLocation({
    required String shipmentId,
  }) async {
    if (!_isSupabaseAvailable) return null;

    try {
      final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
      final row = await _client
          .from(DatabaseConstants.tableShipmentLocations)
          .select('*')
          .eq(ShipmentLocationTableColumns.shipmentId, parsedShipmentId)
          .order(ShipmentLocationTableColumns.recordedAt, ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        return CourierLocationModel.fromDatabase(row);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
