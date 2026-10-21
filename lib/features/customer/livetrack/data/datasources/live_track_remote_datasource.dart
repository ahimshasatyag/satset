import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/live_track_shipment.dart';
import '../models/live_track_shipment_model.dart';

abstract class LiveTrackRemoteDataSource {
  /// Stream data pembaruan posisi live kurir & status pesanan secara real-time via Supabase Realtime
  Stream<List<LiveTrackShipmentModel>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
    String? specificResi,
  });

  /// Mengambil daftar pesanan pelacakan aktif milik pelanggan saat ini dari basis data
  Future<List<LiveTrackShipmentModel>> getActiveTrackingOrders({
    required OrderDirection direction,
    String? specificResi,
  });

  /// Melacak satu pengiriman spesifik berdasarkan nomor resi atau barcode
  Future<LiveTrackShipmentModel?> getShipmentByResi({required String resi});

  /// Menyelesaikan customer_id numerik dari pengguna/sesi autentikasi yang sedang login
  Future<int> resolveCustomerId({String? userId});

  /// Mengambil nomor HP pelanggan untuk mencocokkan kiriman masuk (incoming)
  Future<String?> resolveCustomerPhone({int? customerId});
}

class LiveTrackRemoteDataSourceImpl implements LiveTrackRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  LiveTrackRemoteDataSourceImpl({
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
  Future<int> resolveCustomerId({String? userId}) async {
    // 1. Coba dari currentUser yang dipassing langsung
    if (currentUser != null && currentUser!.id.isNotEmpty) {
      final parsed = int.tryParse(currentUser!.id);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 2. Coba dari userId parameter
    if (userId != null && userId.isNotEmpty) {
      final parsed = int.tryParse(userId);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 3. Coba dari sesi lokal AuthLocalDataSource
    try {
      final savedUser = await _authLocalDataSource?.getUser();
      if (savedUser != null && savedUser.id.isNotEmpty) {
        final parsed = int.tryParse(savedUser.id);
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    // 4. Coba dari Supabase Auth session saat ini
    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        final email = (authUser.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          final res = await _client
              .from(DatabaseConstants.tableUsers)
              .select(DatabaseConstants.colId)
              .eq(DatabaseConstants.colEmail, email)
              .maybeSingle();

          if (res != null && res[DatabaseConstants.colId] != null) {
            final parsed = int.tryParse(res[DatabaseConstants.colId].toString());
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    }

    throw Exception(
        'Akun pelanggan tidak ditemukan atau sesi telah berakhir. Silakan masuk kembali.');
  }

  @override
  Future<String?> resolveCustomerPhone({int? customerId}) async {
    if (!_isSupabaseAvailable) return null;
    try {
      final cId = customerId ?? await resolveCustomerId();
      final res = await _client
          .from(DatabaseConstants.tableUsers)
          .select(UserTableColumns.noHp)
          .eq(DatabaseConstants.colId, cId)
          .maybeSingle();
      return res?[UserTableColumns.noHp]?.toString().trim();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LiveTrackShipmentModel>> getActiveTrackingOrders({
    required OrderDirection direction,
    String? specificResi,
  }) async {
    if (!_isSupabaseAvailable) {
      return const [];
    }

    final customerId = await resolveCustomerId();
    final customerPhone = await resolveCustomerPhone(customerId: customerId);

    try {
      // Query utama ke t_shipments beserta relasi master status, jenis layanan, dan riwayat tracking
      var query = _client.from(DatabaseConstants.tableShipments).select('''
        *,
        ${DatabaseConstants.tableShipmentStatuses}(*),
        ${DatabaseConstants.tableServiceTypes}(*),
        ${DatabaseConstants.tableShipmentTracking}(*, ${DatabaseConstants.tableShipmentStatuses}(*))
      ''');

      if (specificResi != null && specificResi.trim().isNotEmpty) {
        final clean = specificResi.trim();
        query = query.or(
          '${ShipmentTableColumns.nomorResi}.ilike.%$clean%,${ShipmentTableColumns.barcodeValue}.eq.$clean',
        );
      } else {
        if (direction == OrderDirection.outgoing) {
          // Kiriman Saya: paket yang dibuat oleh pelanggan saat ini
          query = query.eq(ShipmentTableColumns.customerId, customerId);
        } else {
          // Paket Masuk: paket yang ditujukan ke nomor telepon pelanggan saat ini
          if (customerPhone != null && customerPhone.isNotEmpty) {
            query = query.eq(ShipmentTableColumns.penerimaNoHp, customerPhone);
          } else {
            // Jika nomor HP belum ada, fallback ke filter customerId
            query = query.eq(ShipmentTableColumns.customerId, customerId);
          }
        }
      }

      final rows = await query.order(DatabaseConstants.colCreatedAt, ascending: false);

      if (rows.isEmpty) {
        return const [];
      }

      // Ambil posisi kurir terkini dari tabel t_shipment_locations untuk paket-paket aktif
      final shipmentIds = rows
          .map((r) => r[ShipmentTableColumns.id])
          .whereType<Object>()
          .map((id) => id.toString())
          .toList();

      final Map<String, Map<String, dynamic>> latestLocations = {};

      if (shipmentIds.isNotEmpty) {
        try {
          final locRows = await _client
              .from(DatabaseConstants.tableShipmentLocations)
              .select()
              .filter(
                ShipmentLocationTableColumns.shipmentId,
                'in',
                '(${shipmentIds.join(",")})',
              )
              .order(ShipmentLocationTableColumns.createdAt, ascending: false);

          for (final loc in locRows) {
            final sId = loc[ShipmentLocationTableColumns.shipmentId]?.toString() ?? '';
            if (sId.isNotEmpty && !latestLocations.containsKey(sId)) {
              latestLocations[sId] = loc;
            }
          }
        } catch (_) {
          // Jika tabel t_shipment_locations belum dibuat atau kosong, fallback tanpa error
        }
      }

      return rows.map((row) {
        final sId = row[ShipmentTableColumns.id]?.toString() ?? '';
        final latestLoc = latestLocations[sId];
        return LiveTrackShipmentModel.fromDatabase(
          row,
          currentCustomerId: customerId,
          currentUserPhone: customerPhone,
          latestLocation: latestLoc,
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal memuat data pelacakan live: $e');
    }
  }

  @override
  Future<LiveTrackShipmentModel?> getShipmentByResi({required String resi}) async {
    final clean = resi.trim();
    if (clean.isEmpty) return null;

    if (!_isSupabaseAvailable) {
      throw Exception('Koneksi Supabase tidak tersedia untuk melacak resi.');
    }

    try {
      final customerId = await resolveCustomerId();
      final customerPhone = await resolveCustomerPhone(customerId: customerId);

      final rows = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*),
            ${DatabaseConstants.tableShipmentTracking}(*, ${DatabaseConstants.tableShipmentStatuses}(*))
          ''')
          .or('${ShipmentTableColumns.nomorResi}.ilike.$clean,${ShipmentTableColumns.barcodeValue}.eq.$clean')
          .limit(1);

      if (rows.isEmpty) return null;

      final row = rows.first;
      final sId = row[ShipmentTableColumns.id]?.toString() ?? '';

      Map<String, dynamic>? latestLoc;
      try {
        final locRows = await _client
            .from(DatabaseConstants.tableShipmentLocations)
            .select()
            .eq(ShipmentLocationTableColumns.shipmentId, sId)
            .order(ShipmentLocationTableColumns.createdAt, ascending: false)
            .limit(1);

        if (locRows.isNotEmpty) {
          latestLoc = locRows.first;
        }
      } catch (_) {}

      return LiveTrackShipmentModel.fromDatabase(
        row,
        currentCustomerId: customerId,
        currentUserPhone: customerPhone,
        latestLocation: latestLoc,
      );
    } catch (e) {
      throw Exception('Gagal melacak pengiriman dengan nomor resi $clean: $e');
    }
  }

  @override
  Stream<List<LiveTrackShipmentModel>> getLiveTrackingOrdersStream({
    required OrderDirection direction,
    String? specificResi,
  }) {
    if (!_isSupabaseAvailable) {
      return Stream.value(const []);
    }

    final controller = StreamController<List<LiveTrackShipmentModel>>.broadcast();

    // 1. Emit snapshot awal secara instan
    getActiveTrackingOrders(direction: direction, specificResi: specificResi)
        .then((initialList) {
      if (!controller.isClosed) {
        controller.add(initialList);
      }
    }).catchError((err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    // 2. Berlangganan ke Supabase Realtime channel postgres changes
    RealtimeChannel? realtimeChannel;

    resolveCustomerId().then((cId) {
      final channelName = 'livetrack_customer_${cId}_${DateTime.now().millisecondsSinceEpoch}';
      realtimeChannel = _client.channel(channelName);

      // Dengarkan perubahan pada t_shipments
      realtimeChannel = realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DatabaseConstants.tableShipments,
            callback: (_) async {
              try {
                final updated = await getActiveTrackingOrders(
                  direction: direction,
                  specificResi: specificResi,
                );
                if (!controller.isClosed) {
                  controller.add(updated);
                }
              } catch (_) {}
            },
          )
          // Dengarkan pergerakan lokasi kurir real-time dari t_shipment_locations
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DatabaseConstants.tableShipmentLocations,
            callback: (_) async {
              try {
                final updated = await getActiveTrackingOrders(
                  direction: direction,
                  specificResi: specificResi,
                );
                if (!controller.isClosed) {
                  controller.add(updated);
                }
              } catch (_) {}
            },
          )
          // Dengarkan pembaruan status jejak perjalanan t_shipment_tracking
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DatabaseConstants.tableShipmentTracking,
            callback: (_) async {
              try {
                final updated = await getActiveTrackingOrders(
                  direction: direction,
                  specificResi: specificResi,
                );
                if (!controller.isClosed) {
                  controller.add(updated);
                }
              } catch (_) {}
            },
          )
          .subscribe();
    }).catchError((_) {});

    controller.onCancel = () {
      if (realtimeChannel != null) {
        _client.removeChannel(realtimeChannel!);
      }
      controller.close();
    };

    return controller.stream;
  }
}
