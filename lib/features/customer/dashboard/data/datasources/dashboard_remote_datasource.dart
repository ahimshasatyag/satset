import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/shipment.dart';
import '../models/shipment_model.dart';
import '../models/user_profile_model.dart';

abstract class DashboardRemoteDataSource {
  /// Stream pembaruan pengiriman aktif pelanggan secara real-time via Supabase Realtime
  Stream<ShipmentModel?> getLiveActiveShipmentStream({required int customerId});

  /// Mengambil pengiriman aktif milik pelanggan saat ini (jika ada)
  Future<ShipmentModel?> getActiveShipment({required int customerId});

  /// Mengambil daftar riwayat pengiriman terbaru milik pelanggan dari t_shipments
  Future<List<ShipmentModel>> getRecentShipments({
    required int customerId,
    int limit = 10,
    String? statusFilter,
  });

  /// Mengambil ringkasan jumlah pengiriman pelanggan berdasarkan 4 kategori status
  Future<ShipmentStatusSummary> getShipmentStatusSummary({required int customerId});

  /// Melacak pengiriman berdasarkan nomor resi atau barcode
  Future<ShipmentModel?> trackShipment(String trackingNumber);

  /// Mengambil data profil pelanggan dari tabel m_users
  Future<UserProfileModel> getUserProfile({String? userId});

  /// Menyelesaikan customer_id numerik dari user/sesi saat ini
  Future<int> resolveCustomerId({String? userId});

  /// Menandai notifikasi sebagai telah dibaca
  Future<void> markNotificationsAsRead();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final String? authToken;
  final User? currentUser;
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;

  DashboardRemoteDataSourceImpl({
    this.authToken,
    this.currentUser,
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
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

    // Jika tidak ditemukan akun terautentikasi, lempar Exception (bukan dummy!)
    throw Exception(
        'Akun pelanggan tidak ditemukan atau sesi telah berakhir. Silakan masuk kembali.');
  }

  @override
  Future<UserProfileModel> getUserProfile({String? userId}) async {
    if (!_isSupabaseAvailable) {
      if (currentUser != null) {
        return UserProfileModel.fromUser(currentUser!);
      }
      throw Exception('Layanan Supabase tidak tersedia.');
    }

    // Cari data di tabel m_users
    Map<String, dynamic>? userRow;

    if (userId != null && userId.isNotEmpty) {
      userRow = await _client
          .from(DatabaseConstants.tableUsers)
          .select()
          .eq(DatabaseConstants.colId, userId)
          .maybeSingle();
    }

    if (userRow == null && currentUser != null && currentUser!.id.isNotEmpty) {
      userRow = await _client
          .from(DatabaseConstants.tableUsers)
          .select()
          .eq(DatabaseConstants.colId, currentUser!.id)
          .maybeSingle();
    }

    if (userRow == null) {
      final authUser = _client.auth.currentUser;
      if (authUser != null && authUser.email != null) {
        userRow = await _client
            .from(DatabaseConstants.tableUsers)
            .select()
            .eq(DatabaseConstants.colEmail, authUser.email!.trim().toLowerCase())
            .maybeSingle();
      }
    }

    if (userRow != null) {
      return UserProfileModel.fromDatabase(userRow);
    }

    if (currentUser != null) {
      return UserProfileModel.fromUser(currentUser!);
    }

    throw Exception('Profil pelanggan tidak ditemukan di basis data SatSet.');
  }

  @override
  Future<ShipmentStatusSummary> getShipmentStatusSummary({
    required int customerId,
  }) async {
    if (!_isSupabaseAvailable) {
      return const ShipmentStatusSummary(
        waitingConfirmationCount: 0,
        inProcessCount: 0,
        inTransitCount: 0,
        deliveredCount: 0,
      );
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableShipments)
          .select(
              '${ShipmentTableColumns.statusId}, ${DatabaseConstants.tableShipmentStatuses}(${DatabaseConstants.colKode})')
          .eq(ShipmentTableColumns.customerId, customerId);

      int waiting = 0;
      int inProcess = 0;
      int inTransit = 0;
      int delivered = 0;

      for (final row in rows) {
        final statusId = int.tryParse(row[ShipmentTableColumns.statusId]?.toString() ?? '');
        final statusMap = row[DatabaseConstants.tableShipmentStatuses] as Map<String, dynamic>?;
        final kode = statusMap?[DatabaseConstants.colKode]?.toString().toUpperCase() ?? '';

        if (statusId == 1 || statusId == 2 || kode == 'PENDING' || kode == 'CONFIRMED') {
          waiting++;
        } else if (statusId == 3 ||
            statusId == 4 ||
            statusId == 6 ||
            kode == 'PICKUP_SCHEDULED' ||
            kode == 'PICKED_UP' ||
            kode == 'AT_SORTING_CENTER') {
          inProcess++;
        } else if (statusId == 5 ||
            statusId == 7 ||
            kode == 'IN_TRANSIT' ||
            kode == 'OUT_FOR_DELIVERY') {
          inTransit++;
        } else if (statusId == 8 || kode == 'DELIVERED') {
          delivered++;
        }
      }

      return ShipmentStatusSummary(
        waitingConfirmationCount: waiting,
        inProcessCount: inProcess,
        inTransitCount: inTransit,
        deliveredCount: delivered,
      );
    } catch (e) {
      throw Exception('Gagal menghitung ringkasan status pengiriman: $e');
    }
  }

  @override
  Future<List<ShipmentModel>> getRecentShipments({
    required int customerId,
    int limit = 10,
    String? statusFilter,
  }) async {
    if (!_isSupabaseAvailable) {
      return const [];
    }

    try {
      var query = _client.from(DatabaseConstants.tableShipments).select('''
        *,
        ${DatabaseConstants.tableShipmentStatuses}(*),
        ${DatabaseConstants.tableServiceTypes}(*),
        ${DatabaseConstants.tableShipmentTracking}(*)
      ''').eq(ShipmentTableColumns.customerId, customerId);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        switch (statusFilter.toLowerCase()) {
          case 'waiting':
            query = query.filter(ShipmentTableColumns.statusId, 'in', '(1,2)');
            break;
          case 'process':
            query = query.filter(ShipmentTableColumns.statusId, 'in', '(3,4,6)');
            break;
          case 'transit':
            query = query.filter(ShipmentTableColumns.statusId, 'in', '(5,7)');
            break;
          case 'delivered':
            query = query.eq(ShipmentTableColumns.statusId, 8);
            break;
        }
      }

      final rows = await query
          .order(DatabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);

      return rows
          .map((item) => ShipmentModel.fromDatabase(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar riwayat pengiriman: $e');
    }
  }

  @override
  Future<ShipmentModel?> getActiveShipment({required int customerId}) async {
    if (!_isSupabaseAvailable) {
      return null;
    }

    try {
      // Cari pengiriman milik pelanggan yang statusnya belum selesai (status_id in 1..7)
      final rows = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*),
            ${DatabaseConstants.tableShipmentTracking}(*)
          ''')
          .eq(ShipmentTableColumns.customerId, customerId)
          .filter(ShipmentTableColumns.statusId, 'in', '(1,2,3,4,5,6,7)')
          .order(DatabaseConstants.colCreatedAt, ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        return ShipmentModel.fromDatabase(rows.first);
      }
      return null;
    } catch (e) {
      // Kembalikan null jika belum ada pengiriman aktif
      return null;
    }
  }

  @override
  Future<ShipmentModel?> trackShipment(String trackingNumber) async {
    final clean = trackingNumber.trim();
    if (clean.isEmpty) return null;

    if (!_isSupabaseAvailable) {
      throw Exception('Koneksi Supabase tidak tersedia untuk melacak resi.');
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*),
            ${DatabaseConstants.tableShipmentTracking}(*)
          ''')
          .or('${ShipmentTableColumns.nomorResi}.ilike.$clean,${ShipmentTableColumns.barcodeValue}.eq.$clean')
          .limit(1);

      if (rows.isNotEmpty) {
        return ShipmentModel.fromDatabase(rows.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal melacak nomor resi $clean: $e');
    }
  }

  @override
  Stream<ShipmentModel?> getLiveActiveShipmentStream({
    required int customerId,
  }) {
    if (!_isSupabaseAvailable) {
      return Stream.value(null);
    }

    final controller = StreamController<ShipmentModel?>.broadcast();

    // Kirim snapshot awal segera
    getActiveShipment(customerId: customerId).then((initial) {
      if (!controller.isClosed) {
        controller.add(initial);
      }
    }).catchError((_) {
      if (!controller.isClosed) {
        controller.add(null);
      }
    });

    // Berlangganan ke realtime perubahan pada tabel t_shipments & t_shipment_tracking
    final channel = _client
        .channel('dashboard_customer_$customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipments,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ShipmentTableColumns.customerId,
            value: customerId,
          ),
          callback: (payload) async {
            try {
              final updated = await getActiveShipment(customerId: customerId);
              if (!controller.isClosed) {
                controller.add(updated);
              }
            } catch (_) {}
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> markNotificationsAsRead() async {
    // Sesuai kebutuhan dapat diperbarui ke tabel notifikasi jika ada
  }
}
