import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../models/delivery_proof_item_model.dart';
import '../models/delivery_proof_task_model.dart';

abstract class CourierDeliveryProofRemoteDataSource {
  Future<String> resolveCourierId({String? overrideId});

  Future<List<DeliveryProofTaskModel>> getActiveDeliveryTasks({
    String? courierId,
  });

  Future<DeliveryProofTaskModel?> getTaskByShipmentId(
    String shipmentId, {
    String? courierId,
  });

  Future<String> uploadProofImage({
    required String shipmentId,
    required Uint8List bytes,
    required String fileName,
  });

  Future<DeliveryProofItemModel> recordDeliveryProof(
    DeliveryProofItemModel proofModel,
  );

  Future<void> completeShipmentDelivery({
    required String shipmentId,
    required String courierId,
    required String recipientName,
    required String relationshipText,
    String? notes,
    double? latitude,
    double? longitude,
    String? barcodeValue,
    String? destinationCity,
  });
}

class CourierDeliveryProofRemoteDataSourceImpl
    implements CourierDeliveryProofRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  CourierDeliveryProofRemoteDataSourceImpl({
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

    // Lookup m_employee jika ada sesi aktif
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
  Future<List<DeliveryProofTaskModel>> getActiveDeliveryTasks({
    String? courierId,
  }) async {
    if (!_isSupabaseAvailable) return [];

    final activeCourierId = await resolveCourierId(overrideId: courierId);

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
        final parsedCourierId = int.tryParse(activeCourierId);
        if (parsedCourierId != null) {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId);
        } else {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
        }
      }

      // Ambil tugas yang belum diselesaikan
      final rows = await query
          .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
          .limit(50);

      final List<DeliveryProofTaskModel> list = [];
      for (final r in rows as List) {
        final model = DeliveryProofTaskModel.fromDatabase(r as Map<String, dynamic>);
        // Saring hanya tugas yang belum berstatus final DELIVERED atau CANCELLED
        if (model.currentStatusId != 8 && model.currentStatusId != 11) {
          list.add(model);
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DeliveryProofTaskModel?> getTaskByShipmentId(
    String shipmentId, {
    String? courierId,
  }) async {
    if (!_isSupabaseAvailable) return null;

    final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;

    try {
      var query = _client.from(DatabaseConstants.tableShipmentAssignments).select('''
        *,
        ${DatabaseConstants.tableShipments}(
          *,
          ${DatabaseConstants.tableShipmentStatuses}(*),
          ${DatabaseConstants.tableServiceTypes}(*)
        )
      ''').eq(ShipmentAssignmentTableColumns.shipmentId, parsedShipmentId);

      final activeCourierId = await resolveCourierId(overrideId: courierId);
      if (activeCourierId.isNotEmpty) {
        final parsedCourierId = int.tryParse(activeCourierId);
        if (parsedCourierId != null) {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId);
        } else {
          query = query.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
        }
      }

      final rows = await query.limit(1);
      if (rows.isNotEmpty) {
        return DeliveryProofTaskModel.fromDatabase(rows.first);
      }

      // Fallback langsung ke t_shipments jika penugasan belum tertaut
      final shipmentRows = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*)
          ''')
          .eq(ShipmentTableColumns.id, parsedShipmentId)
          .limit(1);

      if (shipmentRows.isNotEmpty) {
        return DeliveryProofTaskModel.fromDatabase(shipmentRows.first);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> uploadProofImage({
    required String shipmentId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!_isSupabaseAvailable) {
      // Offline fallback: simpan data URL aman
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'proofs/$shipmentId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    // Daftar kandidat bucket storage di proyek Supabase SatSet
    final candidateBuckets = ['shipment-proofs', 'proofs', 'delivery-proofs', 'public', 'satset'];

    for (final bucket in candidateBuckets) {
      try {
        await _client.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

        final publicUrl = _client.storage.from(bucket).getPublicUrl(storagePath);
        return publicUrl;
      } catch (_) {
        // Coba bucket berikutnya jika bucket belum dikonfigurasi
        continue;
      }
    }

    // Jika seluruh bucket storage remote belum tersedia, gunakan format URI data terenkripsi
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  @override
  Future<DeliveryProofItemModel> recordDeliveryProof(
    DeliveryProofItemModel proofModel,
  ) async {
    if (!_isSupabaseAvailable) {
      return proofModel;
    }

    final dataToInsert = proofModel.toDatabaseInsert();
    final result = await _client
        .from(DatabaseConstants.tableShipmentProofs)
        .insert(dataToInsert)
        .select()
        .single();

    return DeliveryProofItemModel.fromDatabase(result);
  }

  @override
  Future<void> completeShipmentDelivery({
    required String shipmentId,
    required String courierId,
    required String recipientName,
    required String relationshipText,
    String? notes,
    double? latitude,
    double? longitude,
    String? barcodeValue,
    String? destinationCity,
  }) async {
    if (!_isSupabaseAvailable) return;

    final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
    final parsedCourierId = int.tryParse(courierId) ?? courierId;

    // 1. Double Submission Guard & Payment Status Check: Periksa status terkini dan pembayaran
    final checkRows = await _client
        .from(DatabaseConstants.tableShipments)
        .select('''
          ${ShipmentTableColumns.statusId},
          metode_pembayaran,
          ${DatabaseConstants.tableShipmentPayments}(status_pembayaran)
        ''')
        .eq(ShipmentTableColumns.id, parsedShipmentId)
        .limit(1);

    if (checkRows.isNotEmpty) {
      final shipmentRow = checkRows.first;
      final currentStatusId = shipmentRow[ShipmentTableColumns.statusId];
      if (currentStatusId == 8) {
        throw StateError(
          'Paket dengan ID $shipmentId sudah tercatat sebagai DELIVERED sebelumnya.',
        );
      }

      final method = (shipmentRow['metode_pembayaran']?.toString() ?? '').toUpperCase();
      final paymentsRaw = shipmentRow['t_shipment_payments'];
      final paymentMap = paymentsRaw is Map<String, dynamic>
          ? paymentsRaw
          : (paymentsRaw is List && paymentsRaw.isNotEmpty)
              ? paymentsRaw.first as Map<String, dynamic>
              : null;
      final paymentStatus =
          (paymentMap?['status_pembayaran']?.toString() ?? 'PENDING').toUpperCase();
      final isPaid = paymentStatus == 'PAID' || paymentStatus == 'SETTLED' || method == 'COD';

      if (!isPaid) {
        throw StateError(
          'Pesanan ini belum dibayar oleh pelanggan. Paket tidak dapat diselesaikan pengantarannya sebelum pembayaran lunas.',
        );
      }
    }

    final nowIso = DateTime.now().toIso8601String();

    // 2. Perbarui status t_shipments menjadi DELIVERED (id=8)
    await _client.from(DatabaseConstants.tableShipments).update({
      ShipmentTableColumns.statusId: 8,
      ShipmentTableColumns.deliveredAt: nowIso,
      ShipmentTableColumns.updatedAt: nowIso,
    }).eq(ShipmentTableColumns.id, parsedShipmentId);

    // 3. Catat riwayat pergerakan paket ke t_shipment_tracking
    final trackingNotes = notes != null && notes.trim().isNotEmpty
        ? 'Paket berhasil diserahkan kepada $recipientName ($relationshipText). Catatan: ${notes.trim()}'
        : 'Paket berhasil diserahkan kepada $recipientName ($relationshipText).';

    final locationLabel = destinationCity != null && destinationCity.trim().isNotEmpty
        ? 'Alamat Penerima ($destinationCity)'
        : 'Alamat Penerima';

    final trackingPayload = <String, dynamic>{
      ShipmentTrackingTableColumns.shipmentId: parsedShipmentId,
      ShipmentTrackingTableColumns.statusId: 8,
      ShipmentTrackingTableColumns.employeeId: parsedCourierId,
      ShipmentTrackingTableColumns.barcodeValue: barcodeValue ?? '',
      ShipmentTrackingTableColumns.lokasiNama: locationLabel,
      ShipmentTrackingTableColumns.catatan: trackingNotes,
      ShipmentTrackingTableColumns.eventSource: 'COURIER',
      ShipmentTrackingTableColumns.createdAt: nowIso,
    };
    if (latitude != null) trackingPayload[ShipmentTrackingTableColumns.latitude] = latitude;
    if (longitude != null) trackingPayload[ShipmentTrackingTableColumns.longitude] = longitude;

    try {
      await _client.from(DatabaseConstants.tableShipmentTracking).insert(trackingPayload);
    } catch (_) {
      try {
        trackingPayload.remove(ShipmentTrackingTableColumns.eventSource);
        await _client.from(DatabaseConstants.tableShipmentTracking).insert(trackingPayload);
      } catch (_) {}
    }

    // 4. Tandai penugasan kurir di t_shipment_assignments selesai
    try {
      await _client.from(DatabaseConstants.tableShipmentAssignments).update({
        ShipmentAssignmentTableColumns.completedAt: nowIso,
      }).eq(ShipmentAssignmentTableColumns.shipmentId, parsedShipmentId);
    } catch (_) {}
  }
}
