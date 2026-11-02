import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import '../models/admin_activity_model.dart';
import '../models/admin_courier_summary_model.dart';
import '../models/admin_dashboard_stats_model.dart';
import '../models/admin_shipment_detail_model.dart';
import '../models/admin_shipment_table_model.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_shipment_table_item.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

abstract class AdminDashboardRemoteDataSource {
  Future<bool> verifyAdminAccess();
  Future<AdminDashboardStatsModel> getDashboardStats();
  Future<List<AdminCourierSummaryModel>> getCourierSummaries();
  Future<List<AdminActivityModel>> getRecentActivities({int limit = 10});
  Future<AdminShipmentsPaginatedResult> getPaginatedShipments({
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    int? courierIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 10,
  });
  Future<AdminShipmentDetailModel> getShipmentDetail(int shipmentId);
  Future<List<Map<String, dynamic>>> getStatusReferences();
  Future<List<Map<String, dynamic>>> getServiceTypeReferences();
  Future<List<Map<String, dynamic>>> getCourierReferences();
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminDashboardRemoteDataSourceImpl implements AdminDashboardRemoteDataSource {
  final SupabaseClient _client;

  AdminDashboardRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<bool> verifyAdminAccess() async {
    try {
      // 1. Ambil email admin aktif dari sesi login lokal atau Supabase auth
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      final authUser = _client.auth.currentUser;

      // Verifikasi cepat jika sesi lokal admin terdaftar dengan role administrator
      if (savedAdmin != null && (savedAdmin.idUsersRole == 1 || savedAdmin.role == 'admin')) {
        return true;
      }

      final email = (savedAdmin?.email.isNotEmpty == true)
          ? savedAdmin!.email
          : authUser?.email;
      final userId = authUser?.id;

      if (email == null || email.isEmpty) {
        return false;
      }

      // 2. Verifikasi hak akses langsung ke tabel database m_employee
      try {
        final empRes = await _client
            .from(DatabaseConstants.tableEmployee)
            .select('id, id_users_role, email, is_active')
            .eq(EmployeeTableColumns.email, email)
            .maybeSingle();

        if (empRes != null) {
          final roleId = int.tryParse(empRes['id_users_role']?.toString() ?? '');
          final isActive = empRes['is_active'] != false;
          if (roleId == 1 && isActive) {
            return true;
          }
        }
      } catch (_) {}

      // 3. Verifikasi pada m_users: id_users_role = 1 atau role = 'admin'
      try {
        final userRes = await _client
            .from(DatabaseConstants.tableUsers)
            .select('id, id_users_role, role, email')
            .eq(UserTableColumns.email, email)
            .maybeSingle();

        if (userRes != null) {
          final roleId = int.tryParse(userRes['id_users_role']?.toString() ?? '');
          final roleStr = userRes['role']?.toString().toLowerCase();
          if (roleId == 1 || roleStr == 'admin' || roleStr == 'administrator') {
            return true;
          }
        }
      } catch (_) {}

      // 4. Verifikasi berdasarkan user_id jika ada relasi
      if (userId != null) {
        try {
          final userById = await _client
              .from(DatabaseConstants.tableUsers)
              .select('id, id_users_role, role')
              .eq(UserTableColumns.id, userId)
              .maybeSingle();

          if (userById != null) {
            final roleId = int.tryParse(userById['id_users_role']?.toString() ?? '');
            final roleStr = userById['role']?.toString().toLowerCase();
            if (roleId == 1 || roleStr == 'admin') {
              return true;
            }
          }
        } catch (_) {}
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    // 1. Ambil data shipments untuk agregasi pengiriman
    List<Map<String, dynamic>> shipments = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            id,
            status_id,
            total_biaya,
            created_at,
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status)
          ''')
          .order('created_at', ascending: false);
      shipments = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        final fallback = await _client
            .from(DatabaseConstants.tableShipments)
            .select('id, status_id, total_biaya, created_at')
            .order('created_at', ascending: false);
        shipments = List<Map<String, dynamic>>.from(fallback);
      } catch (_) {}
    }

    final totalShipments = shipments.length;
    int pendingCount = 0;
    int inProcessCount = 0;
    int deliveredCount = 0;
    int failedCount = 0;
    int cancelledCount = 0;

    final Map<String, int> statusCountMap = {};
    final Map<String, String> statusNameMap = {};

    for (final s in shipments) {
      final statusMap = s['m_shipment_statuses'] is Map<String, dynamic>
          ? s['m_shipment_statuses'] as Map<String, dynamic>
          : <String, dynamic>{};

      final statusId = int.tryParse(s['status_id']?.toString() ?? '') ?? 1;
      final code = (statusMap['kode'] ?? _resolveStatusCode(statusId)).toString().toUpperCase();
      final name = (statusMap['nama_status'] ?? AdminStatusHelper.getStatusLabel(code)).toString();

      statusCountMap[code] = (statusCountMap[code] ?? 0) + 1;
      statusNameMap[code] = name;

      if (code == 'PENDING' || statusId == 1) {
        pendingCount++;
      } else if (code == 'DELIVERED' || statusId == 8) {
        deliveredCount++;
      } else if (code == 'FAILED_DELIVERY' || statusId == 9) {
        failedCount++;
      } else if (code == 'CANCELLED' || statusId == 11) {
        cancelledCount++;
      } else {
        inProcessCount++;
      }
    }

    // Distribusi status
    final List<AdminStatusDistribution> distributions = [];
    statusCountMap.forEach((code, count) {
      final percentage = totalShipments > 0 ? (count / totalShipments) * 100 : 0.0;
      distributions.add(
        AdminStatusDistribution(
          statusCode: code,
          statusName: statusNameMap[code] ?? AdminStatusHelper.getStatusLabel(code),
          count: count,
          percentage: double.parse(percentage.toStringAsFixed(1)),
        ),
      );
    });

    // 2. Tren Pengiriman (Harian, Mingguan, Bulanan)
    final dailyTrends = _calculateDailyTrends(shipments);
    final weeklyTrends = _calculateWeeklyTrends(shipments);
    final monthlyTrends = _calculateMonthlyTrends(shipments);

    // 3. Data Pelanggan (m_users)
    int totalCustomers = 0;
    try {
      final userCountRes = await _client
          .from(DatabaseConstants.tableUsers)
          .select('id, id_users_role')
          .eq('id_users_role', 3);
      totalCustomers = (userCountRes as List).length;
    } catch (_) {
      try {
        final allUsers = await _client.from(DatabaseConstants.tableUsers).select('id');
        totalCustomers = (allUsers as List).length;
      } catch (_) {}
    }

    // 4. Data Pegawai (m_employee)
    int totalEmployees = 0;
    int totalAdmins = 0;
    int totalCouriers = 0;
    try {
      final empList = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, id_users_role');
      totalEmployees = (empList as List).length;
      for (final e in empList) {
        final roleId = int.tryParse(e['id_users_role']?.toString() ?? '');
        if (roleId == 1) {
          totalAdmins++;
        } else if (roleId == 2) {
          totalCouriers++;
        }
      }
    } catch (_) {}

    // 5. Kurir dengan Penugasan Aktif (t_shipment_assignments)
    int couriersWithAssignment = 0;
    int activeCouriers = 0;
    try {
      final assignments = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select('courier_id, completed_at, unassigned_at')
          .isFilter('completed_at', null)
          .isFilter('unassigned_at', null);

      final uniqueCouriers = <dynamic>{};
      for (final a in (assignments as List)) {
        if (a['courier_id'] != null) {
          uniqueCouriers.add(a['courier_id']);
        }
      }
      couriersWithAssignment = uniqueCouriers.length;
      activeCouriers = couriersWithAssignment > 0 ? couriersWithAssignment : totalCouriers;
    } catch (_) {
      activeCouriers = totalCouriers;
    }

    // 6. Ringkasan Pembayaran (t_shipment_payments)
    AdminPaymentSummary paymentSummary = AdminPaymentSummary.empty;
    try {
      final payments = await _client.from(DatabaseConstants.tableShipmentPayments).select('''
        id,
        jumlah_bayar,
        metode_pembayaran,
        status_pembayaran
      ''');

      num totalAmount = 0;
      num paidAmount = 0;
      num pendingAmount = 0;
      num codAmount = 0;
      int paidCount = 0;
      int pendingCountPay = 0;
      int codCount = 0;

      for (final p in (payments as List)) {
        final amount = num.tryParse(p['jumlah_bayar']?.toString() ?? '0') ?? 0;
        final status = (p['status_pembayaran'] ?? '').toString().toUpperCase();
        final method = (p['metode_pembayaran'] ?? '').toString().toUpperCase();

        totalAmount += amount;

        if (status == 'PAID' || status == 'SUCCESS' || status == 'BERHASIL') {
          paidAmount += amount;
          paidCount++;
        } else if (status == 'PENDING' || status == 'MENUNGGU') {
          pendingAmount += amount;
          pendingCountPay++;
        }

        if (method == 'COD' || status == 'COD') {
          codAmount += amount;
          codCount++;
        }
      }

      paymentSummary = AdminPaymentSummary(
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        pendingAmount: pendingAmount,
        codAmount: codAmount,
        totalCount: payments.length,
        paidCount: paidCount,
        pendingCount: pendingCountPay,
        codCount: codCount,
      );
    } catch (_) {
      // Fallback kalkulasi dari total_biaya pada t_shipments jika t_shipment_payments kosong
      num totalBiayaSum = 0;
      for (final s in shipments) {
        totalBiayaSum += num.tryParse(s['total_biaya']?.toString() ?? '0') ?? 0;
      }
      paymentSummary = AdminPaymentSummary(
        totalAmount: totalBiayaSum,
        paidAmount: totalBiayaSum,
        pendingAmount: 0,
        codAmount: 0,
        totalCount: shipments.length,
        paidCount: shipments.length,
        pendingCount: 0,
        codCount: 0,
      );
    }

    return AdminDashboardStatsModel(
      totalShipments: totalShipments,
      pendingShipments: pendingCount,
      inProcessShipments: inProcessCount,
      deliveredShipments: deliveredCount,
      failedShipments: failedCount,
      cancelledShipments: cancelledCount,
      totalCustomers: totalCustomers,
      totalEmployees: totalEmployees,
      totalAdmins: totalAdmins,
      totalCouriers: totalCouriers,
      activeCouriersCount: activeCouriers,
      couriersWithAssignmentCount: couriersWithAssignment,
      statusDistributions: distributions,
      dailyTrends: dailyTrends,
      weeklyTrends: weeklyTrends,
      monthlyTrends: monthlyTrends,
      paymentSummary: paymentSummary,
    );
  }

  @override
  Future<List<AdminCourierSummaryModel>> getCourierSummaries() async {
    try {
      final couriersRes = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('*')
          .eq('id_users_role', 2);

      final List<AdminCourierSummaryModel> list = [];

      for (final c in (couriersRes as List)) {
        final cId = int.tryParse(c['id']?.toString() ?? '0') ?? 0;

        // Ambil penugasan aktif
        int activeTasks = 0;
        int completedTasks = 0;
        try {
          final tasks = await _client
              .from(DatabaseConstants.tableShipmentAssignments)
              .select('id, completed_at, unassigned_at')
              .eq(ShipmentAssignmentTableColumns.courierId, cId);

          for (final t in (tasks as List)) {
            if (t['completed_at'] != null) {
              completedTasks++;
            } else if (t['unassigned_at'] == null) {
              activeTasks++;
            }
          }
        } catch (_) {}

        // Ambil lokasi terakhir dari t_shipment_locations jika tersedia
        String? lastLoc;
        DateTime? lastUpdate;
        try {
          final loc = await _client
              .from(DatabaseConstants.tableShipmentLocations)
              .select('id, created_at')
              .eq('courier_id', cId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (loc != null) {
            lastLoc = 'Wilayah Tugas Aktif';
            lastUpdate = DateTime.tryParse(loc['created_at']?.toString() ?? '');
          }
        } catch (_) {}

        list.add(
          AdminCourierSummaryModel.fromData(
            employeeMap: c as Map<String, dynamic>,
            activeAssignments: activeTasks,
            completedAssignments: completedTasks,
            lastLocationName: lastLoc,
            lastLocationUpdate: lastUpdate,
          ),
        );
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AdminActivityModel>> getRecentActivities({int limit = 10}) async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .select('''
            *,
            ${DatabaseConstants.tableShipments}(id, nomor_resi),
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
            ${DatabaseConstants.tableEmployee}(id, nama_lengkap)
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map<AdminActivityModel>((r) => AdminActivityModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback query tanpa join jika relasi gagal
      try {
        final fallback = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('*')
            .order('created_at', ascending: false)
            .limit(limit);

        return (fallback as List)
            .map<AdminActivityModel>((r) => AdminActivityModel.fromMap(r as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<AdminShipmentsPaginatedResult> getPaginatedShipments({
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    int? courierIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      var query = _client.from(DatabaseConstants.tableShipments).select('''
        *,
        ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
        ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan),
        ${DatabaseConstants.tableShipmentPayments}(id, metode_pembayaran, status_pembayaran, jumlah_bayar)
      ''');

      // Filter Status
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'ALL') {
        final parsedStatusId = int.tryParse(statusFilter);
        if (parsedStatusId != null) {
          query = query.eq(ShipmentTableColumns.statusId, parsedStatusId);
        }
      }

      // Filter Layanan
      if (serviceFilter != null && serviceFilter.isNotEmpty && serviceFilter != 'ALL') {
        final parsedServiceId = int.tryParse(serviceFilter);
        if (parsedServiceId != null) {
          query = query.eq(ShipmentTableColumns.serviceTypeId, parsedServiceId);
        }
      }

      // Filter Tanggal
      if (startDate != null) {
        query = query.gte(ShipmentTableColumns.createdAt, startDate.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte(ShipmentTableColumns.createdAt, endOfDay.toIso8601String());
      }

      // Pencarian nomor resi / nama pengirim / penerima
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final clean = searchQuery.trim();
        query = query.or('nomor_resi.ilike.%$clean%,pengirim_nama.ilike.%$clean%,penerima_nama.ilike.%$clean%');
      }

      final orderedQuery = query.order(ShipmentTableColumns.createdAt, ascending: false);
      final fromIndex = (page - 1) * pageSize;
      final toIndex = fromIndex + pageSize - 1;

      final res = await orderedQuery.range(fromIndex, toIndex);
      final rawList = List<Map<String, dynamic>>.from(res);

      // Ambil data kurir yang ditugaskan untuk shipment pada halaman ini
      final shipmentIds = rawList.map((e) => e['id']).whereType<int>().toList();
      final Map<int, Map<String, dynamic>> courierByShipmentId = {};

      if (shipmentIds.isNotEmpty) {
        try {
          final assignments = await _client
              .from(DatabaseConstants.tableShipmentAssignments)
              .select('''
                shipment_id,
                ${DatabaseConstants.tableEmployee}(id, nama_lengkap, employee_code, no_hp)
              ''')
              .inFilter('shipment_id', shipmentIds)
              .isFilter('unassigned_at', null);

          for (final a in (assignments as List)) {
            final sId = int.tryParse(a['shipment_id']?.toString() ?? '');
            if (sId != null && a['m_employee'] is Map<String, dynamic>) {
              courierByShipmentId[sId] = a['m_employee'] as Map<String, dynamic>;
            }
          }
        } catch (_) {}
      }

      final items = rawList.map((row) {
        final sId = int.tryParse(row['id']?.toString() ?? '') ?? 0;
        return AdminShipmentTableModel.fromMap(
          row,
          courierMap: courierByShipmentId[sId],
        );
      }).toList();

      // Total count estimasi untuk pagination
      int totalCount = items.length;
      try {
        final countRes = await _client.from(DatabaseConstants.tableShipments).select('id');
        totalCount = (countRes as List).length;
      } catch (_) {}

      final totalPages = (totalCount / pageSize).ceil().clamp(1, 9999);

      return AdminShipmentsPaginatedResult(
        items: items,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
        totalPages: totalPages,
      );
    } catch (_) {
      return AdminShipmentsPaginatedResult.empty;
    }
  }

  @override
  Future<AdminShipmentDetailModel> getShipmentDetail(int shipmentId) async {
    try {
      final res = await _client.from(DatabaseConstants.tableShipments).select('''
        *,
        ${DatabaseConstants.tableShipmentStatuses}(*),
        ${DatabaseConstants.tableServiceTypes}(*),
        ${DatabaseConstants.tableShipmentPayments}(*)
      ''').eq('id', shipmentId).maybeSingle();

      if (res == null) {
        throw Exception('Pengiriman dengan ID #$shipmentId tidak ditemukan.');
      }

      // Ambil kurir penugasan
      Map<String, dynamic>? courierMap;
      try {
        final assign = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('''
              ${DatabaseConstants.tableEmployee}(*)
            ''')
            .eq('shipment_id', shipmentId)
            .isFilter('unassigned_at', null)
            .maybeSingle();

        if (assign != null && assign['m_employee'] is Map<String, dynamic>) {
          courierMap = assign['m_employee'] as Map<String, dynamic>;
        }
      } catch (_) {}

      // Ambil kronologi jejak pelacakan (t_shipment_tracking)
      List<Map<String, dynamic>> trackingList = [];
      try {
        final tracks = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('''
              *,
              ${DatabaseConstants.tableShipmentStatuses}(*),
              ${DatabaseConstants.tableEmployee}(*)
            ''')
            .eq('shipment_id', shipmentId)
            .order('created_at', ascending: false);

        trackingList = List<Map<String, dynamic>>.from(tracks);
      } catch (_) {}

      return AdminShipmentDetailModel.fromMap(
        res,
        courierMap: courierMap,
        trackingList: trackingList,
      );
    } catch (e) {
      throw Exception('Gagal memuat detail pengiriman: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() async {
    try {
      final res = await _client.from(DatabaseConstants.tableShipmentStatuses).select('id, kode, nama_status');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [
        {'id': 1, 'kode': 'PENDING', 'nama_status': 'Menunggu Konfirmasi'},
        {'id': 2, 'kode': 'CONFIRMED', 'nama_status': 'Pesanan Dikonfirmasi'},
        {'id': 3, 'kode': 'PICKUP_SCHEDULED', 'nama_status': 'Dijadwalkan Pickup'},
        {'id': 4, 'kode': 'PICKED_UP', 'nama_status': 'Paket Di-pickup'},
        {'id': 5, 'kode': 'IN_TRANSIT', 'nama_status': 'Dalam Pengiriman'},
        {'id': 6, 'kode': 'AT_SORTING_CENTER', 'nama_status': 'Sorting Center'},
        {'id': 7, 'kode': 'OUT_FOR_DELIVERY', 'nama_status': 'Sedang Diantar'},
        {'id': 8, 'kode': 'DELIVERED', 'nama_status': 'Berhasil Diterima'},
        {'id': 9, 'kode': 'FAILED_DELIVERY', 'nama_status': 'Pengantaran Gagal'},
        {'id': 11, 'kode': 'CANCELLED', 'nama_status': 'Dibatalkan'},
      ];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() async {
    try {
      final res = await _client.from(DatabaseConstants.tableServiceTypes).select('id, kode, nama_layanan');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [
        {'id': 1, 'kode': 'REG', 'nama_layanan': 'Reguler'},
        {'id': 2, 'kode': 'EXP', 'nama_layanan': 'Express / Kilat'},
        {'id': 3, 'kode': 'SD', 'nama_layanan': 'Same Day'},
        {'id': 4, 'kode': 'CARGO', 'nama_layanan': 'Cargo / Berat'},
      ];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCourierReferences() async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, nama_lengkap, employee_code, no_hp')
          .eq('id_users_role', 2);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel('admin_dashboard_realtime_${DateTime.now().millisecondsSinceEpoch}');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipments,
          callback: (payload) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentTracking,
          callback: (payload) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentAssignments,
          callback: (payload) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentPayments,
          callback: (payload) => onDataChanged(),
        )
        .subscribe();

    return channel;
  }

  // ===========================================================================
  // PRIVATE HELPER FUNCTIONS
  // ===========================================================================

  static String _resolveStatusCode(int statusId) {
    switch (statusId) {
      case 1:
        return 'PENDING';
      case 2:
        return 'CONFIRMED';
      case 3:
        return 'PICKUP_SCHEDULED';
      case 4:
        return 'PICKED_UP';
      case 5:
        return 'IN_TRANSIT';
      case 6:
        return 'AT_SORTING_CENTER';
      case 7:
        return 'OUT_FOR_DELIVERY';
      case 8:
        return 'DELIVERED';
      case 9:
        return 'FAILED_DELIVERY';
      case 10:
        return 'RETURNED';
      case 11:
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }

  List<AdminTrendPoint> _calculateDailyTrends(List<Map<String, dynamic>> shipments) {
    final now = DateTime.now();
    final List<AdminTrendPoint> points = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStr = '${date.day}/${date.month}';

      int total = 0;
      int delivered = 0;
      int failed = 0;

      for (final s in shipments) {
        final createdAt = DateTime.tryParse(s['created_at']?.toString() ?? '');
        if (createdAt != null &&
            createdAt.year == date.year &&
            createdAt.month == date.month &&
            createdAt.day == date.day) {
          total++;
          final sId = int.tryParse(s['status_id']?.toString() ?? '') ?? 1;
          if (sId == 8) delivered++;
          if (sId == 9 || sId == 11) failed++;
        }
      }

      points.add(AdminTrendPoint(
        label: dayStr,
        total: total,
        delivered: delivered,
        failed: failed,
      ));
    }

    return points;
  }

  List<AdminTrendPoint> _calculateWeeklyTrends(List<Map<String, dynamic>> shipments) {
    final List<AdminTrendPoint> points = [];
    final now = DateTime.now();

    for (int i = 3; i >= 0; i--) {
      final start = now.subtract(Duration(days: (i + 1) * 7));
      final end = now.subtract(Duration(days: i * 7));
      final label = 'Mgg ${4 - i}';

      int total = 0;
      int delivered = 0;
      int failed = 0;

      for (final s in shipments) {
        final createdAt = DateTime.tryParse(s['created_at']?.toString() ?? '');
        if (createdAt != null && createdAt.isAfter(start) && createdAt.isBefore(end)) {
          total++;
          final sId = int.tryParse(s['status_id']?.toString() ?? '') ?? 1;
          if (sId == 8) delivered++;
          if (sId == 9 || sId == 11) failed++;
        }
      }

      points.add(AdminTrendPoint(
        label: label,
        total: total,
        delivered: delivered,
        failed: failed,
      ));
    }

    return points;
  }

  List<AdminTrendPoint> _calculateMonthlyTrends(List<Map<String, dynamic>> shipments) {
    final List<AdminTrendPoint> points = [];
    final now = DateTime.now();
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    for (int i = 5; i >= 0; i--) {
      int m = now.month - i;
      int y = now.year;
      if (m <= 0) {
        m += 12;
        y -= 1;
      }
      final label = months[m];

      int total = 0;
      int delivered = 0;
      int failed = 0;

      for (final s in shipments) {
        final createdAt = DateTime.tryParse(s['created_at']?.toString() ?? '');
        if (createdAt != null && createdAt.year == y && createdAt.month == m) {
          total++;
          final sId = int.tryParse(s['status_id']?.toString() ?? '') ?? 1;
          if (sId == 8) delivered++;
          if (sId == 9 || sId == 11) failed++;
        }
      }

      points.add(AdminTrendPoint(
        label: label,
        total: total,
        delivered: delivered,
        failed: failed,
      ));
    }

    return points;
  }
}

