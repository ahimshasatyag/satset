import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../models/delivery_proof_summary_model.dart';
import '../models/task_status_detail_model.dart';
import '../models/task_status_step_model.dart';

/// Pengecualian ketika data pengiriman tidak ditemukan di database
class TaskNotFoundException implements Exception {
  final String message;
  const TaskNotFoundException([this.message = 'Tugas pengiriman tidak ditemukan.']);
  @override
  String toString() => message;
}

/// Pengecualian ketika tugas tidak ditugaskan kepada kurir yang sedang login
class TaskNotAssignedException implements Exception {
  final String message;
  const TaskNotAssignedException([
    this.message = 'Tugas ini tidak ditugaskan kepada Anda atau akses otorisasi tidak valid.',
  ]);
  @override
  String toString() => message;
}

/// Pengecualian ketika transisi status operasional tidak valid
class InvalidStatusTransitionException implements Exception {
  final String message;
  const InvalidStatusTransitionException([
    this.message = 'Tahapan perubahan status tidak diizinkan sesuai alur operasional.',
  ]);
  @override
  String toString() => message;
}

/// Kontrak Remote Data Source untuk detail status tugas kurir
abstract class CourierTaskStatusRemoteDataSource {
  Future<String> resolveCourierId({String? overrideId});

  Future<TaskStatusDetailModel> getTaskStatusDetail(
    String shipmentId, {
    String? courierId,
  });

  Future<List<TaskStatusStepModel>> getTaskTimeline(String shipmentId);

  Future<DeliveryProofSummaryModel?> getTaskDeliveryProof(String shipmentId);

  Future<void> updateTaskStatus({
    required String shipmentId,
    required String courierId,
    required int targetStatusId,
    required String targetStatusCode,
    String? notes,
    String? failureReason,
    String? locationName,
    double? latitude,
    double? longitude,
  });

  Stream<TaskStatusDetailModel> subscribeToTaskRealtime(String shipmentId);
}

/// Implementasi Supabase untuk [CourierTaskStatusRemoteDataSource]
class CourierTaskStatusRemoteDataSourceImpl implements CourierTaskStatusRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  CourierTaskStatusRemoteDataSourceImpl({
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

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

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
      }
    }

    return '';
  }

  @override
  Future<TaskStatusDetailModel> getTaskStatusDetail(
    String shipmentId, {
    String? courierId,
  }) async {
    final effectiveCourierId = await resolveCourierId(overrideId: courierId);

    final response = await _client
        .from(DatabaseConstants.tableShipments)
        .select('''
          *,
          ${DatabaseConstants.tableShipmentAssignments}(*),
          ${DatabaseConstants.tableShipmentStatuses}(*),
          ${DatabaseConstants.tableServiceTypes}(*)
        ''')
        .eq(ShipmentTableColumns.id, shipmentId)
        .maybeSingle();

    if (response == null) {
      throw const TaskNotFoundException();
    }

    // Validasi penugasan kurir (RLS & business rule)
    if (effectiveCourierId.isNotEmpty) {
      final assignments = response['t_shipment_assignments'];
      bool isAssigned = false;

      if (assignments is List && assignments.isNotEmpty) {
        isAssigned = assignments.any((a) {
          final cid = a['courier_id']?.toString() ?? '';
          return cid == effectiveCourierId;
        });
      } else if (assignments is Map<String, dynamic>) {
        isAssigned = assignments['courier_id']?.toString() == effectiveCourierId;
      }

      if (!isAssigned) {
        throw const TaskNotAssignedException();
      }
    }

    return TaskStatusDetailModel.fromDatabase(response);
  }

  @override
  Future<List<TaskStatusStepModel>> getTaskTimeline(String shipmentId) async {
    final response = await _client
        .from(DatabaseConstants.tableShipmentTracking)
        .select('''
          *,
          ${DatabaseConstants.tableShipmentStatuses}(*)
        ''')
        .eq(ShipmentTrackingTableColumns.shipmentId, shipmentId)
        .order(ShipmentTrackingTableColumns.createdAt, ascending: true);

    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => TaskStatusStepModel.fromDatabase(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DeliveryProofSummaryModel?> getTaskDeliveryProof(String shipmentId) async {
    final response = await _client
        .from(DatabaseConstants.tableShipmentProofs)
        .select()
        .eq(ShipmentProofTableColumns.shipmentId, shipmentId)
        .order(ShipmentProofTableColumns.createdAt, ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return DeliveryProofSummaryModel.fromDatabase(response);
  }

  @override
  Future<void> updateTaskStatus({
    required String shipmentId,
    required String courierId,
    required int targetStatusId,
    required String targetStatusCode,
    String? notes,
    String? failureReason,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final effectiveCourierId = await resolveCourierId(overrideId: courierId);

    // 1. Verifikasi penugasan kurir aktif
    final assignmentRes = await _client
        .from(DatabaseConstants.tableShipmentAssignments)
        .select()
        .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
        .eq(ShipmentAssignmentTableColumns.courierId, effectiveCourierId)
        .maybeSingle();

    if (assignmentRes == null) {
      throw const TaskNotAssignedException();
    }

    // 2. Siapkan pembaruan status pada t_shipments
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final shipmentUpdate = <String, dynamic>{
      ShipmentTableColumns.statusId: targetStatusId,
      ShipmentTableColumns.updatedAt: nowIso,
    };

    final upperCode = targetStatusCode.toUpperCase();
    if (upperCode == 'PICKED_UP') {
      shipmentUpdate[ShipmentTableColumns.pickedUpAt] = nowIso;
    } else if (upperCode == 'DELIVERED') {
      shipmentUpdate[ShipmentTableColumns.deliveredAt] = nowIso;
    }

    await _client
        .from(DatabaseConstants.tableShipments)
        .update(shipmentUpdate)
        .eq(ShipmentTableColumns.id, shipmentId);

    // 3. Catat riwayat ke t_shipment_tracking
    final trackingPayload = <String, dynamic>{
      ShipmentTrackingTableColumns.shipmentId: shipmentId,
      ShipmentTrackingTableColumns.statusId: targetStatusId,
      ShipmentTrackingTableColumns.employeeId: effectiveCourierId,
      ShipmentTrackingTableColumns.lokasiNama: locationName ?? 'Lokasi Kurir',
      ShipmentTrackingTableColumns.eventSource: 'COURIER',
      ShipmentTrackingTableColumns.createdAt: nowIso,
    };

    if (latitude != null) trackingPayload[ShipmentTrackingTableColumns.latitude] = latitude;
    if (longitude != null) trackingPayload[ShipmentTrackingTableColumns.longitude] = longitude;

    final noteParts = <String>[];
    if (failureReason != null && failureReason.trim().isNotEmpty) {
      noteParts.add('Alasan Gagal: ${failureReason.trim()}');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      noteParts.add(notes.trim());
    }

    if (noteParts.isNotEmpty) {
      trackingPayload[ShipmentTrackingTableColumns.catatan] = noteParts.join('. ');
    }

    try {
      await _client.from(DatabaseConstants.tableShipmentTracking).insert(trackingPayload);
    } catch (_) {
      try {
        trackingPayload.remove(ShipmentTrackingTableColumns.eventSource);
        await _client.from(DatabaseConstants.tableShipmentTracking).insert(trackingPayload);
      } catch (_) {}
    }

    // 4. Jika status DELIVERED, selesaikan penugasan pada t_shipment_assignments
    if (upperCode == 'DELIVERED') {
      await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .update({
            ShipmentAssignmentTableColumns.completedAt: nowIso,
          })
          .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
          .eq(ShipmentAssignmentTableColumns.courierId, effectiveCourierId);
    }
  }

  @override
  Stream<TaskStatusDetailModel> subscribeToTaskRealtime(String shipmentId) {
    late StreamController<TaskStatusDetailModel> controller;
    RealtimeChannel? channel;

    controller = StreamController<TaskStatusDetailModel>.broadcast(
      onListen: () {
        // Ambil data awal
        getTaskStatusDetail(shipmentId).then((data) {
          if (!controller.isClosed) controller.add(data);
        }).catchError((err) {
          if (!controller.isClosed) controller.addError(err);
        });

        // Daftarkan listener Supabase Realtime
        channel = _client.channel('public:t_shipments:id=$shipmentId');
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: DatabaseConstants.tableShipments,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: ShipmentTableColumns.id,
                value: shipmentId,
              ),
              callback: (payload) {
                getTaskStatusDetail(shipmentId).then((data) {
                  if (!controller.isClosed) controller.add(data);
                }).catchError((err) {
                  if (!controller.isClosed) controller.addError(err);
                });
              },
            )
            .subscribe();
      },
      onCancel: () {
        if (channel != null) {
          _client.removeChannel(channel!);
          channel = null;
        }
      },
    );

    return controller.stream;
  }
}
