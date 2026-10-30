import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../models/barcode_scan_log_model.dart';
import '../models/scanned_shipment_model.dart';

abstract class CourierBarcodeScannerRemoteDataSource {
  /// Menyelesaikan ID kurir aktif dari sesi lokal atau Supabase
  Future<String> resolveCourierId({String? overrideId});

  /// Mencari dan memvalidasi paket berdasarkan nomor resi atau barcode_value
  Future<ScannedShipmentModel?> findShipmentByBarcode(
    String barcodeValue, {
    required String activeCourierId,
  });

  /// Memperbarui status alur paket dan mencatat log audit ke basis data
  Future<ScannedShipmentModel> updateShipmentStatusAndLog({
    required String shipmentId,
    required String? assignmentId,
    required String newStatusCode,
    required String courierId,
    String? notes,
    double? latitude,
    double? longitude,
  });

  /// Mencatat riwayat pemindaian ke tabel t_barcode_scans
  Future<void> recordScanAudit(BarcodeScanLogModel log);

  /// Stream pembaruan status paket secara realtime
  Stream<ScannedShipmentModel?> streamShipment(
    String shipmentId, {
    required String activeCourierId,
  });
}

class CourierBarcodeScannerRemoteDataSourceImpl
    implements CourierBarcodeScannerRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  CourierBarcodeScannerRemoteDataSourceImpl({
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
  Future<ScannedShipmentModel?> findShipmentByBarcode(
    String barcodeValue, {
    required String activeCourierId,
  }) async {
    final cleanBarcode = barcodeValue.trim();
    if (cleanBarcode.isEmpty) return null;

    if (!_isSupabaseAvailable) {
      return _getMockScannedShipment(cleanBarcode, activeCourierId);
    }

    try {
      // 1. Query shipment dari t_shipments dengan join relasi
      Map<String, dynamic>? shipmentData;
      try {
        final res = await _client.from(DatabaseConstants.tableShipments).select('''
          *,
          ${DatabaseConstants.tableShipmentStatuses}(*),
          ${DatabaseConstants.tableServiceTypes}(*),
          ${DatabaseConstants.tableShipmentPayments}(*)
        ''').or('barcode_value.eq.$cleanBarcode,nomor_resi.eq.$cleanBarcode').limit(1).maybeSingle();

        shipmentData = res;
      } catch (_) {
        // Fallback tanpa join
        try {
          final res = await _client
              .from(DatabaseConstants.tableShipments)
              .select('*')
              .or('barcode_value.eq.$cleanBarcode,nomor_resi.eq.$cleanBarcode')
              .limit(1)
              .maybeSingle();
          shipmentData = res;
        } catch (_) {
          shipmentData = null;
        }
      }

      if (shipmentData == null) {
        return null;
      }

      final shipmentId = shipmentData['id']?.toString() ?? '';

      // 2. Query penugasan kurir dari t_shipment_assignments
      Map<String, dynamic>? assignmentData;
      if (shipmentId.isNotEmpty) {
        try {
          final parsedCourierId = int.tryParse(activeCourierId);
          var assignQuery = _client
              .from(DatabaseConstants.tableShipmentAssignments)
              .select('*')
              .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId);

          if (parsedCourierId != null) {
            assignQuery = assignQuery.eq(ShipmentAssignmentTableColumns.courierId, parsedCourierId);
          } else if (activeCourierId.isNotEmpty) {
            assignQuery = assignQuery.eq(ShipmentAssignmentTableColumns.courierId, activeCourierId);
          }

          final assignRes = await assignQuery.maybeSingle();
          assignmentData = assignRes;
        } catch (_) {
          // Cari penugasan apapun untuk paket ini
          try {
            final generalAssign = await _client
                .from(DatabaseConstants.tableShipmentAssignments)
                .select('*')
                .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
                .limit(1)
                .maybeSingle();
            assignmentData = generalAssign;
          } catch (_) {
            assignmentData = null;
          }
        }
      }

      return ScannedShipmentModel.fromDatabase(
        shipmentData,
        activeCourierId: activeCourierId,
        assignmentData: assignmentData,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ScannedShipmentModel> updateShipmentStatusAndLog({
    required String shipmentId,
    required String? assignmentId,
    required String newStatusCode,
    required String courierId,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final cleanCode = newStatusCode.trim().toUpperCase();
    final targetStatusId = _resolveStatusId(cleanCode);
    final nowStr = DateTime.now().toIso8601String();

    if (_isSupabaseAvailable) {
      // Validasi status pembayaran (jika belum lunas, tidak boleh diproses/dijemput/diantar)
      if (cleanCode != 'CANCELLED') {
        try {
          final paymentRes = await _client
              .from(DatabaseConstants.tableShipments)
              .select('''
                metode_pembayaran,
                ${DatabaseConstants.tableShipmentPayments}(status_pembayaran)
              ''')
              .eq(ShipmentTableColumns.id, shipmentId)
              .maybeSingle();

          if (paymentRes != null) {
            final method = (paymentRes['metode_pembayaran']?.toString() ?? '').toUpperCase();
            final paymentsRaw = paymentRes['t_shipment_payments'];
            final paymentMap = paymentsRaw is Map<String, dynamic>
                ? paymentsRaw
                : (paymentsRaw is List && paymentsRaw.isNotEmpty)
                    ? paymentsRaw.first as Map<String, dynamic>
                    : null;
            final paymentStatus =
                (paymentMap?['status_pembayaran']?.toString() ?? 'PENDING').toUpperCase();
            final isPaid = paymentStatus == 'PAID' || paymentStatus == 'SETTLED' || method == 'COD';

            if (!isPaid) {
              throw Exception(
                'Pesanan ini belum dibayar oleh pelanggan. Paket tidak dapat dijemput, diproses, atau diantar sebelum pembayaran lunas.',
              );
            }
          }
        } on Exception {
          rethrow;
        } catch (_) {}
      }

      // 1. Coba RPC Supabase jika tersedia
      try {
        final rpcResult = await _client.rpc('update_shipment_status', params: {
          'p_shipment_id': shipmentId,
          'p_status_id': targetStatusId,
          'p_status_code': cleanCode,
          'p_courier_id': int.tryParse(courierId) ?? courierId,
          'p_notes': notes ?? 'Status diubah via barcode scanner kurir menjadi $cleanCode',
          'p_latitude': latitude,
          'p_longitude': longitude,
        });

        if (rpcResult != null && rpcResult is Map<String, dynamic>) {
          return ScannedShipmentModel.fromDatabase(
            rpcResult,
            activeCourierId: courierId,
          );
        }
      } catch (_) {}

      // 2. Transaksi aman langsung: Update t_shipments
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

      // 3. Update atau sinkronkan t_shipment_assignments
      final parsedCourierId = int.tryParse(courierId) ?? courierId;
      if (assignmentId != null && assignmentId.isNotEmpty) {
        final assignmentUpdate = <String, dynamic>{};
        if (cleanCode == 'PICKED_UP' || cleanCode == 'OUT_FOR_DELIVERY') {
          assignmentUpdate[ShipmentAssignmentTableColumns.acceptedAt] = nowStr;
        }
        if (cleanCode == 'DELIVERED' || cleanCode == 'FAILED_DELIVERY' || cleanCode == 'CANCELLED') {
          assignmentUpdate[ShipmentAssignmentTableColumns.completedAt] = nowStr;
        }
        if (notes != null && notes.isNotEmpty) {
          assignmentUpdate[ShipmentAssignmentTableColumns.catatan] = notes;
        }
        if (assignmentUpdate.isNotEmpty) {
          try {
            await _client
                .from(DatabaseConstants.tableShipmentAssignments)
                .update(assignmentUpdate)
                .eq(ShipmentAssignmentTableColumns.id, assignmentId);
          } catch (_) {}
        }
      } else {
        // Buat penugasan baru jika belum ada
        try {
          await _client.from(DatabaseConstants.tableShipmentAssignments).insert({
            ShipmentAssignmentTableColumns.shipmentId: shipmentId,
            ShipmentAssignmentTableColumns.courierId: parsedCourierId,
            ShipmentAssignmentTableColumns.assignedAt: nowStr,
            ShipmentAssignmentTableColumns.acceptedAt: nowStr,
            ShipmentAssignmentTableColumns.catatan: notes ?? 'Dipindai & ditugaskan via Scanner Kurir',
          });
        } catch (_) {}
      }

      // 4. Catat riwayat di t_shipment_tracking
      try {
        final trackingData = <String, dynamic>{
          ShipmentTrackingTableColumns.shipmentId: shipmentId,
          ShipmentTrackingTableColumns.statusId: targetStatusId,
          ShipmentTrackingTableColumns.employeeId: parsedCourierId,
          ShipmentTrackingTableColumns.catatan: notes ?? 'Status diperbarui kurir via Scanner ($cleanCode)',
          ShipmentTrackingTableColumns.eventSource: 'COURIER',
          ShipmentTrackingTableColumns.createdAt: nowStr,
        };
        if (latitude != null) trackingData[ShipmentTrackingTableColumns.latitude] = latitude;
        if (longitude != null) trackingData[ShipmentTrackingTableColumns.longitude] = longitude;

        await _client.from(DatabaseConstants.tableShipmentTracking).insert(trackingData);
      } catch (_) {}

      // 5. Catat ke t_barcode_scans
      try {
        await _client.from(DatabaseConstants.tableBarcodeScans).insert({
          BarcodeScanTableColumns.shipmentId: shipmentId,
          BarcodeScanTableColumns.courierId: parsedCourierId,
          BarcodeScanTableColumns.barcodeValue: shipmentId,
          BarcodeScanTableColumns.scanType: cleanCode,
          BarcodeScanTableColumns.status: 'SUCCESS',
          BarcodeScanTableColumns.notes: notes ?? 'Pemindaian barcode kurir berhasil',
          BarcodeScanTableColumns.scannedAt: nowStr,
        });
      } catch (_) {}

      // 6. Muat ulang data terbaru
      final refreshed = await findShipmentByBarcode(
        shipmentId,
        activeCourierId: courierId,
      );
      if (refreshed != null) {
        return refreshed;
      }
    }

    // Fallback model jika offline / testing
    return _getMockScannedShipment(
      shipmentId,
      courierId,
      overrideStatusCode: cleanCode,
      overrideStatusId: targetStatusId,
    );
  }

  @override
  Future<void> recordScanAudit(BarcodeScanLogModel log) async {
    if (!_isSupabaseAvailable) return;
    try {
      await _client
          .from(DatabaseConstants.tableBarcodeScans)
          .insert(log.toDatabaseMap());
    } catch (_) {
      // Ignored jika tabel audit belum dikonfigurasi sepenuhnya
    }
  }

  @override
  Stream<ScannedShipmentModel?> streamShipment(
    String shipmentId, {
    required String activeCourierId,
  }) {
    if (!_isSupabaseAvailable) {
      return Stream.value(_getMockScannedShipment(shipmentId, activeCourierId));
    }

    return _client
        .from(DatabaseConstants.tableShipments)
        .stream(primaryKey: [DatabaseConstants.colId])
        .eq(DatabaseConstants.colId, shipmentId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return ScannedShipmentModel.fromDatabase(
            rows.first,
            activeCourierId: activeCourierId,
          );
        });
  }

  int _resolveStatusId(String code) {
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
        return 4;
    }
  }

  ScannedShipmentModel _getMockScannedShipment(
    String barcode,
    String courierId, {
    String? overrideStatusCode,
    int? overrideStatusId,
  }) {
    final now = DateTime.now();
    final statusCode = overrideStatusCode ?? 'PICKUP_SCHEDULED';
    final statusId = overrideStatusId ?? 3;

    return ScannedShipmentModel(
      shipmentId: '101',
      assignmentId: 'ASN-101',
      assignedCourierId: courierId,
      trackingNumber: barcode.startsWith('SST-') ? barcode : 'SST-20261023-001',
      barcodeValue: barcode,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusCode == 'PICKED_UP'
          ? 'Paket Telah Di-pickup'
          : statusCode == 'OUT_FOR_DELIVERY'
              ? 'Sedang Diantar ke Penerima'
              : statusCode == 'DELIVERED'
                  ? 'Paket Berhasil Diterima'
                  : 'Dijadwalkan Pickup',
      statusDescription: 'Pengiriman paket sedang dalam penanganan kurir SatSet.',
      senderName: 'Toko Elektronik Makmur',
      senderPhone: '081234567890',
      senderAddress: 'Jl. Ahmad Yani No. 45, Kebon Jeruk',
      senderCity: 'Jakarta Barat',
      receiverName: 'Siti Rahmawati',
      receiverPhone: '085712345678',
      receiverAddress: 'Jl. Merdeka Selatan Blok C No. 12',
      receiverCity: 'Jakarta Pusat',
      serviceTypeId: 2,
      serviceTypeName: 'Express (1-2 Hari)',
      serviceTypeCode: 'EXP',
      weightGram: 1800,
      notes: 'Harap hati-hati, barang elektronik mudah pecah.',
      paymentMethod: 'TRANSFER',
      paymentStatus: 'PAID',
      estimatedArrival: now.add(const Duration(hours: 4)),
      pickedUpAt: statusCode == 'PICKED_UP' || statusCode == 'DELIVERED' ? now : null,
      deliveredAt: statusCode == 'DELIVERED' ? now : null,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
      isAssignedToActiveCourier: true,
    );
  }
}
