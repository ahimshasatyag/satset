import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/courier_task.dart';
import '../models/courier_task_model.dart';

abstract class CourierTasksRemoteDataSource {
  /// Mengambil daftar tugas kurir terpaginasi
  Future<List<CourierTaskModel>> getTasks({
    String? courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  /// Memperbarui status alur tugas kurir
  Future<CourierTaskModel> updateTaskStatus({
    required String taskId,
    required String shipmentId,
    required String newStatusCode,
    String? notes,
    double? latitude,
    double? longitude,
  });

  /// Stream pembaruan daftar tugas secara real-time via Supabase Realtime
  Stream<List<CourierTaskModel>> streamTasks({String? courierId});

  /// Menghitung rekap jumlah tugas kurir per kelompok
  Future<Map<CourierTaskGroup, int>> getTaskCounts({String? courierId});

  /// Menyelesaikan ID kurir aktif
  Future<String> resolveCourierId({String? overrideId});
}

class CourierTasksRemoteDataSourceImpl implements CourierTasksRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  RealtimeChannel? _tasksChannel;
  StreamController<List<CourierTaskModel>>? _streamController;

  CourierTasksRemoteDataSourceImpl({
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
  Future<List<CourierTaskModel>> getTasks({
    String? courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final activeCourierId = await resolveCourierId(overrideId: courierId);

    // Hanya gunakan mock data jika di lingkungan testing offline tanpa Supabase
    if (!_isSupabaseAvailable) {
      return _getMockTasks(
        courierId: activeCourierId.isNotEmpty ? activeCourierId : '1',
        type: type,
        group: group,
        searchQuery: searchQuery,
      );
    }

    try {
      final fromIndex = (page - 1) * limit;
      final toIndex = fromIndex + limit - 1;
      dynamic rows = [];

      // 1. Query penugasan kurir dari t_shipment_assignments dengan join relasi t_shipments,
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

        if (activeCourierId.isNotEmpty) {
          final parsedInt = int.tryParse(activeCourierId);
          if (parsedInt != null) {
            query = query.eq(ShipmentAssignmentTableColumns.courierId, parsedInt);
          } else {
            query = query.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
          }
        }

        rows = await query
            .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
            .range(fromIndex, toIndex);
      } catch (_) {
        // Fallback join langsung ke t_shipments jika relasi bertingkat gagal
        try {
          var fallbackQuery = _client.from(DatabaseConstants.tableShipmentAssignments).select('''
            *,
            ${DatabaseConstants.tableShipments}(*)
          ''');

          if (activeCourierId.isNotEmpty) {
            final parsedInt = int.tryParse(activeCourierId);
            if (parsedInt != null) {
              fallbackQuery = fallbackQuery.eq(ShipmentAssignmentTableColumns.courierId, parsedInt);
            } else {
              fallbackQuery = fallbackQuery.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
            }
          }

          rows = await fallbackQuery
              .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
              .range(fromIndex, toIndex);
        } catch (_) {
          rows = [];
        }
      }

      // 2. Jika kurir belum memiliki data penugasan di t_shipment_assignments,
      // otomatis tugaskan pengiriman aktif di t_shipments ke kurir ini
      if ((rows as List).isEmpty && activeCourierId.isNotEmpty) {
        try {
          final unassignedShipments = await _client
              .from(DatabaseConstants.tableShipments)
              .select('''
                *,
                ${DatabaseConstants.tableShipmentStatuses}(*),
                ${DatabaseConstants.tableServiceTypes}(*)
              ''')
              .lte(ShipmentTableColumns.statusId, 7)
              .order(ShipmentTableColumns.id, ascending: false)
              .limit(5);

          if ((unassignedShipments as List).isNotEmpty) {
            final parsedCourierId = int.tryParse(activeCourierId) ?? activeCourierId;
            final nowStr = DateTime.now().toIso8601String();

            for (final s in unassignedShipments) {
              try {
                await _client.from(DatabaseConstants.tableShipmentAssignments).insert({
                  ShipmentAssignmentTableColumns.shipmentId: s['id'],
                  ShipmentAssignmentTableColumns.courierId: parsedCourierId,
                  ShipmentAssignmentTableColumns.assignedAt: nowStr,
                  ShipmentAssignmentTableColumns.catatan: 'Penugasan Pengiriman SatSet Delivery',
                });
              } catch (_) {}
            }

            final reloaded = await _client.from(DatabaseConstants.tableShipmentAssignments).select('''
              *,
              ${DatabaseConstants.tableShipments}(
                *,
                ${DatabaseConstants.tableShipmentStatuses}(*),
                ${DatabaseConstants.tableServiceTypes}(*)
              )
            ''').eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId)
              .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false);

            rows = reloaded;
          }
        } catch (_) {}
      }

      List<CourierTaskModel> list = (rows as List)
          .map<CourierTaskModel>((r) => CourierTaskModel.fromDatabase(
                r as Map<String, dynamic>,
                currentCourierId: activeCourierId,
              ))
          .toList();

      // 3. Filter berdasarkan tipe penugasan (PICKUP vs DELIVERY)
      if (type != null) {
        list = list.where((task) => task.taskType == type).toList();
      }

      // 4. Filter lokal untuk pencarian teks & kelompok status
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

      if (group != null) {
        list = list.where((task) => task.taskGroup == group).toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<CourierTaskModel> updateTaskStatus({
    required String taskId,
    required String shipmentId,
    required String newStatusCode,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final activeCourierId = await resolveCourierId();
    final cleanCode = newStatusCode.toUpperCase();
    final targetStatusId = _statusIdFromCode(cleanCode);

    if (!_isSupabaseAvailable) {
      // Mock update untuk testing
      return _createMockTask(
        id: taskId,
        shipmentId: shipmentId,
        courierId: activeCourierId,
        statusCode: cleanCode,
        statusId: targetStatusId,
        notes: notes,
      );
    }

    try {
      // 1. Coba melalui RPC backend Supabase jika tersedia
      try {
        final rpcResult = await _client.rpc(
          'update_courier_task_status',
          params: {
            'p_task_id': taskId,
            'p_shipment_id': shipmentId,
            'p_courier_id': activeCourierId,
            'p_status_code': cleanCode,
            'p_notes': notes,
            'p_latitude': latitude,
            'p_longitude': longitude,
          },
        );
        if (rpcResult != null && rpcResult is Map<String, dynamic>) {
          return CourierTaskModel.fromDatabase(
            rpcResult,
            currentCourierId: activeCourierId,
          );
        }
      } catch (_) {
        // Jika RPC belum dibuat di DB, lanjutkan ke alur transaksi langsung
      }

      // 2. Transaksi langsung: Update t_shipments
      final nowStr = DateTime.now().toIso8601String();
      final shipmentUpdateData = <String, dynamic>{
        ShipmentTableColumns.statusId: targetStatusId,
        ShipmentTableColumns.updatedAt: nowStr,
      };

      if (cleanCode == 'PICKED_UP') {
        shipmentUpdateData[ShipmentTableColumns.pickedUpAt] = nowStr;
      } else if (cleanCode == 'DELIVERED') {
        shipmentUpdateData[ShipmentTableColumns.deliveredAt] = nowStr;
      }

      await _client
          .from(DatabaseConstants.tableShipments)
          .update(shipmentUpdateData)
          .eq(ShipmentTableColumns.id, shipmentId);

      // 3. Update penugasan di t_shipment_assignments
      final assignmentUpdateData = <String, dynamic>{};
      if (cleanCode == 'PICKED_UP' || cleanCode == 'OUT_FOR_DELIVERY') {
        assignmentUpdateData[ShipmentAssignmentTableColumns.acceptedAt] = nowStr;
      }
      if (cleanCode == 'DELIVERED' || cleanCode == 'FAILED_DELIVERY' || cleanCode == 'CANCELLED') {
        assignmentUpdateData[ShipmentAssignmentTableColumns.completedAt] = nowStr;
      }
      if (notes != null && notes.isNotEmpty) {
        assignmentUpdateData[ShipmentAssignmentTableColumns.catatan] = notes;
      }

      if (assignmentUpdateData.isNotEmpty) {
        await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .update(assignmentUpdateData)
            .eq(ShipmentAssignmentTableColumns.id, taskId);
      }

      // 4. Catat riwayat jejak di t_shipment_tracking
      final trackingData = <String, dynamic>{
        ShipmentTrackingTableColumns.shipmentId: shipmentId,
        ShipmentTrackingTableColumns.statusId: targetStatusId,
        ShipmentTrackingTableColumns.employeeId: int.tryParse(activeCourierId) ?? activeCourierId,
        ShipmentTrackingTableColumns.catatan: notes ?? 'Status diperbarui oleh kurir menjadi $cleanCode',
        ShipmentTrackingTableColumns.eventSource: 'COURIER_APP',
        ShipmentTrackingTableColumns.createdAt: nowStr,
      };
      if (latitude != null) trackingData[ShipmentTrackingTableColumns.latitude] = latitude;
      if (longitude != null) trackingData[ShipmentTrackingTableColumns.longitude] = longitude;

      await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .insert(trackingData);

      // 5. Muat ulang data terbaru tugas tersebut
      try {
        final refreshed = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('''
              *,
              ${DatabaseConstants.tableShipments}(*)
            ''')
            .eq(ShipmentAssignmentTableColumns.id, taskId)
            .maybeSingle();

        if (refreshed != null) {
          return CourierTaskModel.fromDatabase(
            refreshed,
            currentCourierId: activeCourierId,
          );
        }
      } catch (_) {}

      try {
        final directShipment = await _client
            .from(DatabaseConstants.tableShipments)
            .select()
            .eq('id', shipmentId)
            .maybeSingle();
        if (directShipment != null) {
          return CourierTaskModel.fromDatabase(
            {
              'id': taskId,
              'shipment_id': shipmentId,
              'courier_id': activeCourierId,
              'status': (cleanCode == 'DELIVERED' ? 'COMPLETED' : 'IN_PROGRESS'),
              't_shipments': directShipment,
            },
            currentCourierId: activeCourierId,
          );
        }
      } catch (_) {}

      return _createMockTask(
        id: taskId,
        shipmentId: shipmentId,
        courierId: activeCourierId,
        statusCode: cleanCode,
        statusId: targetStatusId,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Gagal memperbarui status tugas kurir: $e');
    }
  }

  @override
  Stream<List<CourierTaskModel>> streamTasks({String? courierId}) {
    _streamController?.close();
    _streamController = StreamController<List<CourierTaskModel>>.broadcast();

    Future.microtask(() async {
      try {
        final activeId = await resolveCourierId(overrideId: courierId);
        final initial = await getTasks(courierId: activeId);
        if (!_streamController!.isClosed) {
          _streamController!.add(initial);
        }

        if (_isSupabaseAvailable) {
          _tasksChannel?.unsubscribe();
          _tasksChannel = _client.channel('courier_tasks_$activeId');

          _tasksChannel!
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: DatabaseConstants.tableShipmentAssignments,
                callback: (payload) async {
                  try {
                    final updated = await getTasks(courierId: activeId);
                    if (!_streamController!.isClosed) {
                      _streamController!.add(updated);
                    }
                  } catch (_) {}
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: DatabaseConstants.tableShipments,
                callback: (payload) async {
                  try {
                    final updated = await getTasks(courierId: activeId);
                    if (!_streamController!.isClosed) {
                      _streamController!.add(updated);
                    }
                  } catch (_) {}
                },
              )
              .subscribe();
        }
      } catch (_) {
        if (!_streamController!.isClosed) {
          _streamController!.add([]);
        }
      }
    });

    return _streamController!.stream;
  }

  @override
  Future<Map<CourierTaskGroup, int>> getTaskCounts({String? courierId}) async {
    final tasks = await getTasks(courierId: courierId, limit: 100);
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (final t in tasks) {
      switch (t.taskGroup) {
        case CourierTaskGroup.pending:
          pending++;
          break;
        case CourierTaskGroup.inProgress:
          inProgress++;
          break;
        case CourierTaskGroup.completed:
          completed++;
          break;
      }
    }

    return {
      CourierTaskGroup.pending: pending,
      CourierTaskGroup.inProgress: inProgress,
      CourierTaskGroup.completed: completed,
    };
  }

  int _statusIdFromCode(String code) {
    switch (code) {
      case 'PENDING':
        return 1;
      case 'CONFIRMED':
        return 2;
      case 'PICKUP_SCHEDULED':
        return 3;
      case 'PICKED_UP':
        return 4;
      case 'IN_TRANSIT':
        return 5;
      case 'AT_SORTING_CENTER':
        return 6;
      case 'OUT_FOR_DELIVERY':
        return 7;
      case 'DELIVERED':
        return 8;
      case 'FAILED_DELIVERY':
        return 9;
      case 'RETURNED':
        return 10;
      case 'CANCELLED':
        return 11;
      default:
        return 5;
    }
  }

  // ===========================================================================
  // MOCK HELPER (UNTUK TESTING & ENVIRONMENT OFFLINE)
  // ===========================================================================
  List<CourierTaskModel> _getMockTasks({
    required String courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
  }) {
    final now = DateTime.now();
    final tasks = [
      CourierTaskModel(
        id: 'ASN-101',
        shipmentId: '101',
        courierId: courierId,
        trackingNumber: 'SST-20261023-001',
        barcodeValue: 'SST-20261023-001',
        taskType: CourierTaskType.pickup,
        statusId: 3,
        statusCode: 'PICKUP_SCHEDULED',
        statusName: 'Dijadwalkan untuk Pickup',
        statusDescription: 'Kurir telah ditugaskan dan dijadwalkan menuju lokasi penjemputan',
        assignmentStatus: 'ASSIGNED',
        senderName: 'Toko Elektronik Makmur',
        senderPhone: '081234567890',
        senderAddress: 'Jl. Surya Kencana No. 45, Kebayoran Baru',
        senderCity: 'Jakarta Selatan',
        senderLatitude: -6.2412,
        senderLongitude: 106.8012,
        receiverName: 'Budi Santoso',
        receiverPhone: '081987654321',
        receiverAddress: 'Jl. Merdeka No. 12, Gambir',
        receiverCity: 'Jakarta Pusat',
        receiverLatitude: -6.1751,
        receiverLongitude: 106.8272,
        serviceTypeId: 4,
        serviceTypeName: 'Instant Courier',
        serviceTypeCode: 'INST',
        weightGram: 1500,
        itemName: 'Headset Gaming & Aksesoris',
        itemValue: 450000,
        totalFee: 30000,
        paymentMethod: 'TRANSFER',
        notes: 'Mohon dijemput sebelum jam 12 siang',
        assignedAt: now.subtract(const Duration(hours: 1)),
        estimatedArrival: now.add(const Duration(minutes: 45)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      CourierTaskModel(
        id: 'ASN-102',
        shipmentId: '102',
        courierId: courierId,
        trackingNumber: 'SST-20261023-002',
        barcodeValue: 'SST-20261023-002',
        taskType: CourierTaskType.delivery,
        statusId: 7,
        statusCode: 'OUT_FOR_DELIVERY',
        statusName: 'Sedang Diantar Kurir',
        statusDescription: 'Kurir sedang membawa paket menuju alamat penerima',
        assignmentStatus: 'IN_PROGRESS',
        senderName: 'Distributor Fesyen Bandung',
        senderPhone: '082111223344',
        senderAddress: 'Jl. Sukajadi No. 102',
        senderCity: 'Bandung',
        senderLatitude: -6.8920,
        senderLongitude: 107.5980,
        receiverName: 'Siti Rahmawati',
        receiverPhone: '085712345678',
        receiverAddress: 'Apartemen Sudirman Tower Lt. 15 No. 15B',
        receiverCity: 'Jakarta Selatan',
        receiverLatitude: -6.2185,
        receiverLongitude: 106.8188,
        serviceTypeId: 2,
        serviceTypeName: 'Express',
        serviceTypeCode: 'EXP',
        weightGram: 800,
        itemName: 'Baju Batik Sutra',
        itemValue: 250000,
        totalFee: 25000,
        paymentMethod: 'TRANSFER',
        notes: 'Titipkan di resepsionis lobi jika tidak ada di tempat',
        assignedAt: now.subtract(const Duration(hours: 3)),
        estimatedArrival: now.add(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      CourierTaskModel(
        id: 'ASN-103',
        shipmentId: '103',
        courierId: courierId,
        trackingNumber: 'SST-20261023-003',
        barcodeValue: 'SST-20261023-003',
        taskType: CourierTaskType.delivery,
        statusId: 8,
        statusCode: 'DELIVERED',
        statusName: 'Terkirim',
        statusDescription: 'Paket telah berhasil diserahkan kepada penerima di alamat tujuan',
        assignmentStatus: 'COMPLETED',
        senderName: 'Sentra Herbal Alami',
        senderPhone: '081399887766',
        senderAddress: 'Ruko Boulevard Barat Blok B3',
        senderCity: 'Jakarta Utara',
        receiverName: 'Ahmad Fauzi',
        receiverPhone: '081800112233',
        receiverAddress: 'Jl. Rawamangun Muka No. 8',
        receiverCity: 'Jakarta Timur',
        serviceTypeId: 1,
        serviceTypeName: 'Reguler',
        serviceTypeCode: 'REG',
        weightGram: 1200,
        itemName: 'Suplemen Madu Hutan',
        itemValue: 180000,
        totalFee: 15000,
        paymentMethod: 'COD',
        notes: 'Selesai diserahkan kepada penerima langsung',
        assignedAt: now.subtract(const Duration(hours: 5)),
        completedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    var filtered = tasks;
    if (type != null) {
      filtered = filtered.where((t) => t.taskType == type).toList();
    }
    if (group != null) {
      filtered = filtered.where((t) => t.taskGroup == group).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where((t) {
        return t.trackingNumber.toLowerCase().contains(q) ||
            t.receiverName.toLowerCase().contains(q) ||
            t.senderName.toLowerCase().contains(q);
      }).toList();
    }
    return filtered;
  }

  CourierTaskModel _createMockTask({
    required String id,
    required String shipmentId,
    required String courierId,
    required String statusCode,
    required int statusId,
    String? notes,
  }) {
    final now = DateTime.now();
    return CourierTaskModel(
      id: id,
      shipmentId: shipmentId,
      courierId: courierId,
      trackingNumber: 'SST-20261023-$shipmentId',
      barcodeValue: 'SST-20261023-$shipmentId',
      taskType: statusId <= 4 ? CourierTaskType.pickup : CourierTaskType.delivery,
      statusId: statusId,
      statusCode: statusCode,
      statusName: CourierTaskModel.statusNameFromCode(statusCode),
      statusDescription: CourierTaskModel.statusDescriptionFromCode(
        statusCode,
        CourierTaskModel.statusNameFromCode(statusCode),
      ),
      assignmentStatus: statusId >= 8 ? 'COMPLETED' : 'IN_PROGRESS',
      senderName: 'Pengirim SatSet',
      senderPhone: '08123456789',
      senderAddress: 'Jl. Asal No. 1',
      senderCity: 'Jakarta Selatan',
      receiverName: 'Penerima SatSet',
      receiverPhone: '08987654321',
      receiverAddress: 'Jl. Tujuan No. 2',
      receiverCity: 'Jakarta Pusat',
      serviceTypeId: 1,
      serviceTypeName: 'Reguler',
      serviceTypeCode: 'REG',
      weightGram: 1000,
      itemName: 'Paket SatSet',
      itemValue: 100000,
      totalFee: 15000,
      paymentMethod: 'TRANSFER',
      notes: notes,
      assignedAt: now,
      completedAt: statusId >= 8 ? now : null,
      createdAt: now,
      updatedAt: now,
    );
  }
}
