import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';

import '../../domain/entities/admin_delivery_item.dart';
import '../models/admin_assignable_courier_model.dart';
import '../models/admin_delivery_detail_model.dart';
import '../models/admin_delivery_item_model.dart';

abstract class AdminDeliveryRemoteDataSource {
  Future<bool> verifyAdminAccess();
  Future<AdminDeliveriesPaginatedResult> getPaginatedDeliveries({
    String tabCategory = AdminDeliveryTab.all,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });
  Future<AdminDeliveryDetailModel> getDeliveryDetail(int shipmentId);
  Future<List<AdminAssignableCourierModel>> getAssignableCouriers();
  Future<void> confirmShipmentOrder({required int shipmentId, String? notes});
  Future<void> assignCourierToShipment({
    required int shipmentId,
    required int courierId,
    String? notes,
  });
  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String targetStatusCode,
    String? lokasiNama,
    String? notes,
  });
  Future<void> handleFailedDelivery({
    required int shipmentId,
    required String resolutionAction,
    int? reassignCourierId,
    String? notes,
  });
  Future<List<Map<String, dynamic>>> getStatusReferences();
  Future<List<Map<String, dynamic>>> getServiceTypeReferences();
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminDeliveryRemoteDataSourceImpl
    implements AdminDeliveryRemoteDataSource {
  final SupabaseClient _client;

  AdminDeliveryRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  @override
  Future<bool> verifyAdminAccess() async {
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      final authUser = _client.auth.currentUser;

      if (savedAdmin != null &&
          (savedAdmin.idUsersRole == 1 || savedAdmin.role == 'admin')) {
        return true;
      }

      final email = (savedAdmin?.email.isNotEmpty == true)
          ? savedAdmin!.email
          : authUser?.email;

      if (email == null || email.isEmpty) {
        return false;
      }

      try {
        final empRes = await _client
            .from(DatabaseConstants.tableEmployee)
            .select('id, id_users_role, email, is_active')
            .eq(EmployeeTableColumns.email, email)
            .maybeSingle();

        if (empRes != null) {
          final roleId = int.tryParse(
            empRes['id_users_role']?.toString() ?? '',
          );
          final isActive = empRes['is_active'] != false;
          if (roleId == 1 && isActive) {
            return true;
          }
        }
      } catch (_) {}

      try {
        final userRes = await _client
            .from(DatabaseConstants.tableUsers)
            .select('id, id_users_role, role, email')
            .eq(UserTableColumns.email, email)
            .maybeSingle();

        if (userRes != null) {
          final roleId = int.tryParse(
            userRes['id_users_role']?.toString() ?? '',
          );
          final roleStr = userRes['role']?.toString().toLowerCase();
          if (roleId == 1 || roleStr == 'admin' || roleStr == 'administrator') {
            return true;
          }
        }
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int?> _getActiveAdminEmployeeId() async {
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      if (savedAdmin != null) {
        final parsed = int.tryParse(savedAdmin.id);
        if (parsed != null && parsed > 0) return parsed;
        if (savedAdmin.email.isNotEmpty) {
          final emp = await _client
              .from(DatabaseConstants.tableEmployee)
              .select('id')
              .eq(EmployeeTableColumns.email, savedAdmin.email)
              .maybeSingle();
          if (emp != null) {
            return int.tryParse(emp['id']?.toString() ?? '');
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _requireAdminAuthorization() async {
    final isAuthorized = await verifyAdminAccess();
    if (!isAuthorized) {
      throw Exception(
        'Akses Ditolak: Tindakan ini hanya diizinkan untuk Administrator resmi (id_users_role = 1).',
      );
    }
  }

  @override
  Future<AdminDeliveriesPaginatedResult> getPaginatedDeliveries({
    String tabCategory = AdminDeliveryTab.all,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Ambil seluruh baris pengiriman dengan relasi yang tersedia
    List<Map<String, dynamic>> rawShipments = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
            ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan),
            ${DatabaseConstants.tableShipmentPayments}(id, nomor_pembayaran, metode_pembayaran, status_pembayaran, jumlah_bayar, paid_at)
          ''')
          .order(ShipmentTableColumns.createdAt, ascending: false);
      rawShipments = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      final fallback = await _client
          .from(DatabaseConstants.tableShipments)
          .select('*')
          .order(ShipmentTableColumns.createdAt, ascending: false);
      rawShipments = List<Map<String, dynamic>>.from(fallback);
    }

    if (rawShipments.isEmpty) {
      return AdminDeliveriesPaginatedResult.empty;
    }

    // 2. Ambil profil customer dari m_users untuk customer_id yang terlibat
    final customerIds = rawShipments
        .map((e) => int.tryParse(e['customer_id']?.toString() ?? ''))
        .whereType<int>()
        .toSet()
        .toList();
    final Map<int, Map<String, dynamic>> customerById = {};
    if (customerIds.isNotEmpty) {
      try {
        final usersRes = await _client
            .from(DatabaseConstants.tableUsers)
            .select('id, nama_lengkap, email, no_hp')
            .inFilter('id', customerIds);
        for (final u in (usersRes as List)) {
          final uId = int.tryParse(u['id']?.toString() ?? '');
          if (uId != null) {
            customerById[uId] = Map<String, dynamic>.from(u as Map);
          }
        }
      } catch (_) {}
    }

    // 3. Ambil penugasan kurir aktif dari t_shipment_assignments + m_employee
    final shipmentIds = rawShipments
        .map((e) => int.tryParse(e['id']?.toString() ?? ''))
        .whereType<int>()
        .toList();
    final Map<int, Map<String, dynamic>> courierByShipmentId = {};
    final Map<int, int> assignmentIdByShipmentId = {};

    if (shipmentIds.isNotEmpty) {
      try {
        final assignmentsRes = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('''
              id,
              shipment_id,
              courier_id,
              unassigned_at,
              ${DatabaseConstants.tableEmployee}(id, nama_lengkap, employee_code, no_hp, email)
            ''')
            .inFilter('shipment_id', shipmentIds)
            .isFilter('unassigned_at', null);

        for (final a in (assignmentsRes as List)) {
          final sId = int.tryParse(a['shipment_id']?.toString() ?? '');
          final assignId = int.tryParse(a['id']?.toString() ?? '');
          if (sId != null) {
            if (assignId != null) {
              assignmentIdByShipmentId[sId] = assignId;
            }
            if (a['m_employee'] is Map<String, dynamic>) {
              courierByShipmentId[sId] = Map<String, dynamic>.from(
                a['m_employee'] as Map,
              );
            }
          }
        }
      } catch (_) {}
    }

    // 4. Konversi menjadi list AdminDeliveryItemModel
    final allItems = rawShipments.map((row) {
      final sId = int.tryParse(row['id']?.toString() ?? '') ?? 0;
      final cId = int.tryParse(row['customer_id']?.toString() ?? '');
      return AdminDeliveryItemModel.fromMap(
        row,
        customerMap: cId != null ? customerById[cId] : null,
        courierMap: courierByShipmentId[sId],
        activeAssignmentId: assignmentIdByShipmentId[sId],
      );
    }).toList();

    // 5. Hitung jumlah pengiriman untuk masing-masing Tab Kategori
    final Map<String, int> tabCounts = {
      AdminDeliveryTab.all: allItems.length,
      AdminDeliveryTab.waitingConfirmation: 0,
      AdminDeliveryTab.waitingAssignment: 0,
      AdminDeliveryTab.inProcess: 0,
      AdminDeliveryTab.outForDelivery: 0,
      AdminDeliveryTab.delivered: 0,
      AdminDeliveryTab.failed: 0,
      AdminDeliveryTab.cancelled: 0,
    };

    for (final item in allItems) {
      final code = item.statusKode.toUpperCase();
      if (code == 'PENDING') {
        tabCounts[AdminDeliveryTab.waitingConfirmation] =
            (tabCounts[AdminDeliveryTab.waitingConfirmation] ?? 0) + 1;
      }
      if (!item.hasCourierAssigned &&
          code != 'DELIVERED' &&
          code != 'CANCELLED' &&
          code != 'RETURNED') {
        tabCounts[AdminDeliveryTab.waitingAssignment] =
            (tabCounts[AdminDeliveryTab.waitingAssignment] ?? 0) + 1;
      }
      if (code == 'CONFIRMED' ||
          code == 'PICKUP_SCHEDULED' ||
          code == 'PICKED_UP' ||
          code == 'IN_TRANSIT' ||
          code == 'AT_SORTING_CENTER') {
        tabCounts[AdminDeliveryTab.inProcess] =
            (tabCounts[AdminDeliveryTab.inProcess] ?? 0) + 1;
      }
      if (code == 'OUT_FOR_DELIVERY') {
        tabCounts[AdminDeliveryTab.outForDelivery] =
            (tabCounts[AdminDeliveryTab.outForDelivery] ?? 0) + 1;
      }
      if (code == 'DELIVERED') {
        tabCounts[AdminDeliveryTab.delivered] =
            (tabCounts[AdminDeliveryTab.delivered] ?? 0) + 1;
      }
      if (code == 'FAILED_DELIVERY' || code == 'RETURNED') {
        tabCounts[AdminDeliveryTab.failed] =
            (tabCounts[AdminDeliveryTab.failed] ?? 0) + 1;
      }
      if (code == 'CANCELLED') {
        tabCounts[AdminDeliveryTab.cancelled] =
            (tabCounts[AdminDeliveryTab.cancelled] ?? 0) + 1;
      }
    }

    // 6. Terapkan Filter Tab, Pencarian, dan Filter Spesifik
    final filteredItems = allItems.where((item) {
      final code = item.statusKode.toUpperCase();

      // Filter Tab Kategori
      switch (tabCategory) {
        case AdminDeliveryTab.waitingConfirmation:
          if (code != 'PENDING') return false;
          break;
        case AdminDeliveryTab.waitingAssignment:
          if (item.hasCourierAssigned ||
              code == 'DELIVERED' ||
              code == 'CANCELLED' ||
              code == 'RETURNED') {
            return false;
          }
          break;
        case AdminDeliveryTab.inProcess:
          if (code != 'CONFIRMED' &&
              code != 'PICKUP_SCHEDULED' &&
              code != 'PICKED_UP' &&
              code != 'IN_TRANSIT' &&
              code != 'AT_SORTING_CENTER') {
            return false;
          }
          break;
        case AdminDeliveryTab.outForDelivery:
          if (code != 'OUT_FOR_DELIVERY') return false;
          break;
        case AdminDeliveryTab.delivered:
          if (code != 'DELIVERED') return false;
          break;
        case AdminDeliveryTab.failed:
          if (code != 'FAILED_DELIVERY' && code != 'RETURNED') return false;
          break;
        case AdminDeliveryTab.cancelled:
          if (code != 'CANCELLED') return false;
          break;
        case AdminDeliveryTab.all:
        default:
          break;
      }

      // Filter Status Spesifik
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'ALL') {
        final matchId = item.statusId?.toString() == statusFilter;
        final matchCode =
            item.statusKode.toUpperCase() == statusFilter.toUpperCase();
        if (!matchId && !matchCode) return false;
      }

      // Filter Jenis Layanan
      if (serviceFilter != null &&
          serviceFilter.isNotEmpty &&
          serviceFilter != 'ALL') {
        final matchId = item.serviceTypeId?.toString() == serviceFilter;
        final matchCode =
            item.serviceKode.toUpperCase() == serviceFilter.toUpperCase();
        if (!matchId && !matchCode) return false;
      }

      // Filter Metode Pembayaran
      if (paymentMethodFilter != null &&
          paymentMethodFilter.isNotEmpty &&
          paymentMethodFilter != 'ALL') {
        if (item.metodePembayaran.toUpperCase() !=
            paymentMethodFilter.toUpperCase()) {
          return false;
        }
      }

      // Filter Status Pembayaran
      if (paymentStatusFilter != null &&
          paymentStatusFilter.isNotEmpty &&
          paymentStatusFilter != 'ALL') {
        if (item.statusPembayaran.toUpperCase() !=
            paymentStatusFilter.toUpperCase()) {
          return false;
        }
      }

      // Filter Kurir
      if (courierFilter != null &&
          courierFilter.isNotEmpty &&
          courierFilter != 'ALL') {
        if (courierFilter == 'UNASSIGNED') {
          if (item.hasCourierAssigned) return false;
        } else {
          if (item.courierId?.toString() != courierFilter) return false;
        }
      }

      // Filter Rentang Tanggal
      if (startDate != null && item.createdAt != null) {
        final startOfDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        if (item.createdAt!.isBefore(startOfDay)) return false;
      }
      if (endDate != null && item.createdAt != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (item.createdAt!.isAfter(endOfDay)) return false;
      }

      // Pencarian: nomor resi, barcode, nama pengirim/customer, atau nama penerima
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchResi = item.nomorResi.toLowerCase().contains(q);
        final matchBarcode = item.barcodeValue.toLowerCase().contains(q);
        final matchCustomer = item.customerNama.toLowerCase().contains(q);
        final matchPengirim = item.pengirimNama.toLowerCase().contains(q);
        final matchPenerima = item.penerimaNama.toLowerCase().contains(q);
        final matchKotaAsal = item.pengirimKota.toLowerCase().contains(q);
        final matchKotaTujuan = item.penerimaKota.toLowerCase().contains(q);

        if (!matchResi &&
            !matchBarcode &&
            !matchCustomer &&
            !matchPengirim &&
            !matchPenerima &&
            !matchKotaAsal &&
            !matchKotaTujuan) {
          return false;
        }
      }

      return true;
    }).toList();

    // 7. Pengurutan Kolom (Sorting)
    filteredItems.sort((a, b) {
      int comparison = 0;
      switch (sortColumn) {
        case 'nomor_resi':
          comparison = a.nomorResi.compareTo(b.nomorResi);
          break;
        case 'pengirim_nama':
          comparison = a.pengirimNama.toLowerCase().compareTo(
            b.pengirimNama.toLowerCase(),
          );
          break;
        case 'penerima_nama':
          comparison = a.penerimaNama.toLowerCase().compareTo(
            b.penerimaNama.toLowerCase(),
          );
          break;
        case 'total_berat_gram':
          comparison = a.totalBeratGram.compareTo(b.totalBeratGram);
          break;
        case 'total_biaya':
          comparison = a.totalBiaya.compareTo(b.totalBiaya);
          break;
        case 'status':
          comparison = a.statusNama.compareTo(b.statusNama);
          break;
        case 'created_at':
        default:
          final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = dateA.compareTo(dateB);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    // 8. Paginasi
    final totalCount = filteredItems.length;
    final totalPages = (totalCount / pageSize).ceil().clamp(1, 9999);
    final safePage = page.clamp(1, totalPages);
    final startIndex = (safePage - 1) * pageSize;
    final pagedItems = startIndex < totalCount
        ? filteredItems.skip(startIndex).take(pageSize).toList()
        : <AdminDeliveryItemModel>[];

    return AdminDeliveriesPaginatedResult(
      items: pagedItems,
      totalCount: totalCount,
      currentPage: safePage,
      pageSize: pageSize,
      totalPages: totalPages,
      tabCounts: tabCounts,
    );
  }

  @override
  Future<AdminDeliveryDetailModel> getDeliveryDetail(int shipmentId) async {
    // 1. Ambil data utama pengiriman dari t_shipments beserta status, layanan, dan pembayaran
    final res = await _client
        .from(DatabaseConstants.tableShipments)
        .select('''
      *,
      ${DatabaseConstants.tableShipmentStatuses}(*),
      ${DatabaseConstants.tableServiceTypes}(*),
      ${DatabaseConstants.tableShipmentPayments}(*)
    ''')
        .eq('id', shipmentId)
        .maybeSingle();

    if (res == null) {
      throw Exception(
        'Data pengiriman dengan ID #$shipmentId tidak ditemukan.',
      );
    }

    // 2. Ambil profil customer dari m_users jika customer_id tersedia
    Map<String, dynamic>? customerMap;
    final customerId = int.tryParse(res['customer_id']?.toString() ?? '');
    if (customerId != null) {
      try {
        final userRes = await _client
            .from(DatabaseConstants.tableUsers)
            .select('id, nama_lengkap, email, no_hp, alamat_lengkap')
            .eq('id', customerId)
            .maybeSingle();
        if (userRes != null) {
          customerMap = Map<String, dynamic>.from(userRes);
        }
      } catch (_) {}
    }

    // 3. Ambil penugasan kurir aktif dari t_shipment_assignments & m_employee
    Map<String, dynamic>? assignmentMap;
    Map<String, dynamic>? courierMap;
    try {
      final assignRes = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select('''
            *,
            ${DatabaseConstants.tableEmployee}(*)
          ''')
          .eq('shipment_id', shipmentId)
          .isFilter('unassigned_at', null)
          .order('assigned_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (assignRes != null) {
        assignmentMap = Map<String, dynamic>.from(assignRes);
        if (assignRes['m_employee'] is Map<String, dynamic>) {
          courierMap = Map<String, dynamic>.from(
            assignRes['m_employee'] as Map,
          );
        }
      }
    } catch (_) {}

    // 4. Ambil kronologi perubahan status dari t_shipment_tracking secara berurutan
    List<Map<String, dynamic>> trackingList = [];
    try {
      final tracksRes = await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableEmployee}(id, nama_lengkap, employee_code)
          ''')
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false);

      trackingList = List<Map<String, dynamic>>.from(tracksRes);
    } catch (_) {
      try {
        final fallbackTracks = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('*')
            .eq('shipment_id', shipmentId)
            .order('created_at', ascending: false);
        trackingList = List<Map<String, dynamic>>.from(fallbackTracks);
      } catch (_) {}
    }

    // 5. Ambil lokasi terakhir kurir dari t_shipment_locations apabila tersedia
    Map<String, dynamic>? lastLocationMap;
    final assignedCourierId = int.tryParse(courierMap?['id']?.toString() ?? '');
    try {
      final byShipmentLoc = await _client
          .from(DatabaseConstants.tableShipmentLocations)
          .select('*')
          .eq('shipment_id', shipmentId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (byShipmentLoc != null) {
        lastLocationMap = Map<String, dynamic>.from(byShipmentLoc);
      } else if (assignedCourierId != null) {
        final byCourierLoc = await _client
            .from(DatabaseConstants.tableShipmentLocations)
            .select('*')
            .eq('courier_id', assignedCourierId)
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (byCourierLoc != null) {
          lastLocationMap = Map<String, dynamic>.from(byCourierLoc);
        }
      }
    } catch (_) {}

    return AdminDeliveryDetailModel.fromMap(
      res,
      customerMap: customerMap,
      assignmentMap: assignmentMap,
      courierMap: courierMap,
      trackingList: trackingList,
      lastLocationMap: lastLocationMap,
    );
  }

  @override
  Future<List<AdminAssignableCourierModel>> getAssignableCouriers() async {
    try {
      // Ambil seluruh employee dengan id_users_role = 2 (Kurir)
      final couriersRes = await _client
          .from(DatabaseConstants.tableEmployee)
          .select(
            'id, employee_code, nama_lengkap, email, no_hp, alamat_lengkap, foto_url, is_active, id_users_role',
          )
          .eq(EmployeeTableColumns.idUsersRole, 2)
          .order(EmployeeTableColumns.namaLengkap, ascending: true);

      // Hitung beban penugasan dari t_shipment_assignments
      final Map<int, int> activeCountByCourier = {};
      final Map<int, int> completedCountByCourier = {};
      try {
        final assignmentsRes = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('courier_id, completed_at, unassigned_at');

        for (final a in (assignmentsRes as List)) {
          final cId = int.tryParse(a['courier_id']?.toString() ?? '');
          if (cId == null) continue;
          if (a['completed_at'] != null) {
            completedCountByCourier[cId] =
                (completedCountByCourier[cId] ?? 0) + 1;
          } else if (a['unassigned_at'] == null) {
            activeCountByCourier[cId] = (activeCountByCourier[cId] ?? 0) + 1;
          }
        }
      } catch (_) {}

      final List<AdminAssignableCourierModel> result = [];
      for (final row in (couriersRes as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final cId = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
        result.add(
          AdminAssignableCourierModel.fromMap(
            map,
            activeAssignmentsCount: activeCountByCourier[cId] ?? 0,
            completedAssignmentsCount: completedCountByCourier[cId] ?? 0,
          ),
        );
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil daftar kurir dari database: $e');
    }
  }

  Future<int> _resolveStatusIdByCode(
    String statusCode, {
    int fallbackId = 2,
  }) async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode')
          .ilike('kode', statusCode)
          .maybeSingle();
      if (res != null) {
        final id = int.tryParse(res['id']?.toString() ?? '');
        if (id != null) return id;
      }
    } catch (_) {}
    return fallbackId;
  }

  @override
  Future<void> confirmShipmentOrder({
    required int shipmentId,
    String? notes,
  }) async {
    await _requireAdminAuthorization();

    // Periksa status pengiriman saat ini
    final shipment = await _client
        .from(DatabaseConstants.tableShipments)
        .select(
          'id, nomor_resi, barcode_value, status_id, ${DatabaseConstants.tableShipmentStatuses}(kode)',
        )
        .eq('id', shipmentId)
        .maybeSingle();

    if (shipment == null) {
      throw Exception('Data pengiriman tidak ditemukan.');
    }

    final statusMap = shipment['m_shipment_statuses'] is Map<String, dynamic>
        ? shipment['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};
    final currentCode = (statusMap['kode'] ?? '').toString().toUpperCase();

    if (currentCode == 'DELIVERED' || currentCode == 'CANCELLED') {
      throw Exception(
        'Pesanan dengan status $currentCode tidak dapat dikonfirmasi ulang.',
      );
    }

    final confirmedStatusId = await _resolveStatusIdByCode(
      'CONFIRMED',
      fallbackId: 2,
    );
    final adminEmpId = await _getActiveAdminEmployeeId();
    final nowIso = DateTime.now().toIso8601String();

    // Update status pada t_shipments
    await _client
        .from(DatabaseConstants.tableShipments)
        .update({
          ShipmentTableColumns.statusId: confirmedStatusId,
          ShipmentTableColumns.updatedAt: nowIso,
        })
        .eq(ShipmentTableColumns.id, shipmentId);

    // Catat ke kronologi audit t_shipment_tracking
    final trackingNotes = (notes != null && notes.trim().isNotEmpty)
        ? notes.trim()
        : 'Pesanan pengiriman telah dikonfirmasi oleh Administrator dan siap dijadwalkan kurir.';

    await _client.from(DatabaseConstants.tableShipmentTracking).insert({
      ShipmentTrackingTableColumns.shipmentId: shipmentId,
      ShipmentTrackingTableColumns.statusId: confirmedStatusId,
      ShipmentTrackingTableColumns.employeeId: ?adminEmpId,
      ShipmentTrackingTableColumns.barcodeValue:
          shipment['barcode_value'] ?? shipment['nomor_resi'],
      ShipmentTrackingTableColumns.lokasiNama: 'Pusat Kendali Admin SatSet',
      ShipmentTrackingTableColumns.catatan: trackingNotes,
      ShipmentTrackingTableColumns.eventSource: 'ADMIN_PORTAL',
      ShipmentTrackingTableColumns.createdAt: nowIso,
    });
  }

  @override
  Future<void> assignCourierToShipment({
    required int shipmentId,
    required int courierId,
    String? notes,
  }) async {
    await _requireAdminAuthorization();

    // 1. Validasi data kurir pada m_employee (id_users_role = 2 & is_active = true)
    final courierRes = await _client
        .from(DatabaseConstants.tableEmployee)
        .select('id, nama_lengkap, employee_code, id_users_role, is_active')
        .eq(EmployeeTableColumns.id, courierId)
        .maybeSingle();

    if (courierRes == null) {
      throw Exception('Data kurir tidak ditemukan pada tabel m_employee.');
    }

    final roleId = int.tryParse(courierRes['id_users_role']?.toString() ?? '');
    final isActive = courierRes['is_active'] != false;

    if (roleId != 2) {
      throw Exception(
        'Pegawai yang dipilih bukan Kurir resmi (id_users_role harus bernilai 2).',
      );
    }
    if (!isActive) {
      throw Exception(
        'Kurir ${courierRes['nama_lengkap']} sedang berstatus nonaktif dan tidak dapat menerima penugasan.',
      );
    }

    // 2. Validasi data pengiriman pada t_shipments
    final shipment = await _client
        .from(DatabaseConstants.tableShipments)
        .select(
          'id, nomor_resi, barcode_value, status_id, ${DatabaseConstants.tableShipmentStatuses}(kode)',
        )
        .eq('id', shipmentId)
        .maybeSingle();

    if (shipment == null) {
      throw Exception('Data pengiriman tidak ditemukan.');
    }

    final statusMap = shipment['m_shipment_statuses'] is Map<String, dynamic>
        ? shipment['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};
    final currentCode = (statusMap['kode'] ?? '').toString().toUpperCase();

    if (currentCode == 'DELIVERED' || currentCode == 'CANCELLED') {
      throw Exception(
        'Pengiriman yang sudah $currentCode tidak dapat ditugaskan kurir.',
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    final adminEmpId = await _getActiveAdminEmployeeId();

    // 3. Cek penugasan aktif pada t_shipment_assignments agar tidak terjadi penugasan ganda/bertentangan
    final existingActive = await _client
        .from(DatabaseConstants.tableShipmentAssignments)
        .select('id, courier_id')
        .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
        .isFilter(ShipmentAssignmentTableColumns.unassignedAt, null)
        .isFilter(ShipmentAssignmentTableColumns.completedAt, null);

    for (final active in (existingActive as List)) {
      final existingCourierId = int.tryParse(
        active['courier_id']?.toString() ?? '',
      );
      if (existingCourierId == courierId) {
        throw Exception(
          'Kurir ${courierRes['nama_lengkap']} sudah memiliki penugasan aktif untuk pengiriman ini.',
        );
      }
      // Nonaktifkan penugasan lama dengan mengisi unassigned_at
      final oldAssignId = int.tryParse(active['id']?.toString() ?? '');
      if (oldAssignId != null) {
        await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .update({ShipmentAssignmentTableColumns.unassignedAt: nowIso})
            .eq(ShipmentAssignmentTableColumns.id, oldAssignId);
      }
    }

    // 4. Simpan penugasan baru ke t_shipment_assignments
    final courierName =
        courierRes['nama_lengkap']?.toString() ?? 'Kurir SatSet';
    final courierCode =
        courierRes['employee_code']?.toString() ?? 'KUR-$courierId';
    final assignNote = (notes != null && notes.trim().isNotEmpty)
        ? notes.trim()
        : 'Ditugaskan kepada kurir $courierName ($courierCode) oleh Administrator.';

    await _client.from(DatabaseConstants.tableShipmentAssignments).insert({
      ShipmentAssignmentTableColumns.shipmentId: shipmentId,
      ShipmentAssignmentTableColumns.courierId: courierId,
      ShipmentAssignmentTableColumns.assignedBy: ?adminEmpId,
      ShipmentAssignmentTableColumns.assignedAt: nowIso,
      ShipmentAssignmentTableColumns.catatan: assignNote,
      ShipmentAssignmentTableColumns.createdAt: nowIso,
    });

    // 5. Jika status masih PENDING atau CONFIRMED, perbarui ke PICKUP_SCHEDULED
    int targetStatusId =
        int.tryParse(shipment['status_id']?.toString() ?? '2') ?? 2;
    if (currentCode == 'PENDING' ||
        currentCode == 'CONFIRMED' ||
        currentCode.isEmpty) {
      targetStatusId = await _resolveStatusIdByCode(
        'PICKUP_SCHEDULED',
        fallbackId: 3,
      );
      await _client
          .from(DatabaseConstants.tableShipments)
          .update({
            ShipmentTableColumns.statusId: targetStatusId,
            ShipmentTableColumns.updatedAt: nowIso,
          })
          .eq(ShipmentTableColumns.id, shipmentId);
    }

    // 6. Catat dalam kronologi t_shipment_tracking
    await _client.from(DatabaseConstants.tableShipmentTracking).insert({
      ShipmentTrackingTableColumns.shipmentId: shipmentId,
      ShipmentTrackingTableColumns.statusId: targetStatusId,
      ShipmentTrackingTableColumns.employeeId: courierId,
      ShipmentTrackingTableColumns.barcodeValue:
          shipment['barcode_value'] ?? shipment['nomor_resi'],
      ShipmentTrackingTableColumns.lokasiNama: 'Penugasan Armada SatSet',
      ShipmentTrackingTableColumns.catatan: assignNote,
      ShipmentTrackingTableColumns.eventSource: 'ADMIN_ASSIGNMENT',
      ShipmentTrackingTableColumns.createdAt: nowIso,
    });
  }

  @override
  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String targetStatusCode,
    String? lokasiNama,
    String? notes,
  }) async {
    await _requireAdminAuthorization();

    final shipment = await _client
        .from(DatabaseConstants.tableShipments)
        .select('id, nomor_resi, barcode_value, status_id')
        .eq('id', shipmentId)
        .maybeSingle();

    if (shipment == null) {
      throw Exception('Data pengiriman tidak ditemukan.');
    }

    final cleanCode = targetStatusCode.trim().toUpperCase();
    final targetStatusId = await _resolveStatusIdByCode(
      cleanCode,
      fallbackId: _defaultStatusIdForCode(cleanCode),
    );
    final nowIso = DateTime.now().toIso8601String();
    final adminEmpId = await _getActiveAdminEmployeeId();

    final Map<String, dynamic> updatePayload = {
      ShipmentTableColumns.statusId: targetStatusId,
      ShipmentTableColumns.updatedAt: nowIso,
    };

    if (cleanCode == 'PICKED_UP') {
      updatePayload[ShipmentTableColumns.pickedUpAt] = nowIso;
    } else if (cleanCode == 'DELIVERED') {
      updatePayload[ShipmentTableColumns.deliveredAt] = nowIso;
    } else if (cleanCode == 'CANCELLED') {
      updatePayload[ShipmentTableColumns.cancelledAt] = nowIso;
    }

    await _client
        .from(DatabaseConstants.tableShipments)
        .update(updatePayload)
        .eq(ShipmentTableColumns.id, shipmentId);

    // Jika DELIVERED atau CANCELLED, perbarui status penugasan aktif di t_shipment_assignments
    if (cleanCode == 'DELIVERED') {
      try {
        await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .update({ShipmentAssignmentTableColumns.completedAt: nowIso})
            .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
            .isFilter(ShipmentAssignmentTableColumns.unassignedAt, null)
            .isFilter(ShipmentAssignmentTableColumns.completedAt, null);
      } catch (_) {}
    } else if (cleanCode == 'CANCELLED') {
      try {
        await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .update({ShipmentAssignmentTableColumns.unassignedAt: nowIso})
            .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
            .isFilter(ShipmentAssignmentTableColumns.unassignedAt, null)
            .isFilter(ShipmentAssignmentTableColumns.completedAt, null);
      } catch (_) {}
    }

    // Catat ke t_shipment_tracking
    await _client.from(DatabaseConstants.tableShipmentTracking).insert({
      ShipmentTrackingTableColumns.shipmentId: shipmentId,
      ShipmentTrackingTableColumns.statusId: targetStatusId,
      ShipmentTrackingTableColumns.employeeId: ?adminEmpId,
      ShipmentTrackingTableColumns.barcodeValue:
          shipment['barcode_value'] ?? shipment['nomor_resi'],
      ShipmentTrackingTableColumns.lokasiNama:
          (lokasiNama != null && lokasiNama.trim().isNotEmpty)
          ? lokasiNama.trim()
          : 'Pusat Operasional Admin',
      ShipmentTrackingTableColumns.catatan:
          (notes != null && notes.trim().isNotEmpty)
          ? notes.trim()
          : 'Status pengiriman diperbarui menjadi $cleanCode oleh Administrator.',
      ShipmentTrackingTableColumns.eventSource: 'ADMIN_PORTAL',
      ShipmentTrackingTableColumns.createdAt: nowIso,
    });
  }

  @override
  Future<void> handleFailedDelivery({
    required int shipmentId,
    required String resolutionAction,
    int? reassignCourierId,
    String? notes,
  }) async {
    await _requireAdminAuthorization();

    final action = resolutionAction.toUpperCase();
    final customNotes = (notes != null && notes.trim().isNotEmpty)
        ? notes.trim()
        : null;

    switch (action) {
      case 'RESCHEDULE_DELIVERY':
        await updateShipmentStatus(
          shipmentId: shipmentId,
          targetStatusCode: 'OUT_FOR_DELIVERY',
          lokasiNama: 'Hub Pengantaran Ulang SatSet',
          notes: customNotes ?? 'Pengiriman yang gagal telah dijadwalkan ulang untuk pengantaran kembali oleh Administrator.',
        );
        break;
      case 'REASSIGN_COURIER':
        if (reassignCourierId == null) {
          throw Exception('Pilih kurir pengganti terlebih dahulu.');
        }
        await assignCourierToShipment(
          shipmentId: shipmentId,
          courierId: reassignCourierId,
          notes:
              customNotes ??
              'Penugasan ulang kurir untuk menangani kendala pengiriman gagal.',
        );
        await updateShipmentStatus(
          shipmentId: shipmentId,
          targetStatusCode: 'OUT_FOR_DELIVERY',
          lokasiNama: 'Hub Penugasan Ulang Kurir',
          notes: customNotes ?? 'Paket diserahkan kepada kurir pengganti untuk pengantaran ulang.',
        );
        break;
      case 'RETURN_TO_SENDER':
        await updateShipmentStatus(
          shipmentId: shipmentId,
          targetStatusCode: 'RETURNED',
          lokasiNama: 'Hub Retur SatSet',
          notes: customNotes ?? 'Paket diproses untuk dikembalikan ke pengirim (Return to Sender).',
        );
        break;
      case 'CANCEL_SHIPMENT':
        await updateShipmentStatus(
          shipmentId: shipmentId,
          targetStatusCode: 'CANCELLED',
          lokasiNama: 'Pusat Kendali Admin SatSet',
          notes: customNotes ?? 'Pengiriman dibatalkan oleh Administrator setelah penanganan kendala.',
        );
        break;
      default:
        throw Exception('Tindakan resolusi pengiriman gagal tidak dikenali.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode, nama_status')
          .order('id', ascending: true);
      final list = List<Map<String, dynamic>>.from(res);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return [
      {'id': 1, 'kode': 'PENDING', 'nama_status': 'Menunggu Konfirmasi'},
      {'id': 2, 'kode': 'CONFIRMED', 'nama_status': 'Pesanan Dikonfirmasi'},
      {
        'id': 3,
        'kode': 'PICKUP_SCHEDULED',
        'nama_status': 'Dijadwalkan Pickup',
      },
      {'id': 4, 'kode': 'PICKED_UP', 'nama_status': 'Paket Di-pickup'},
      {'id': 5, 'kode': 'IN_TRANSIT', 'nama_status': 'Dalam Pengiriman'},
      {'id': 6, 'kode': 'AT_SORTING_CENTER', 'nama_status': 'Sorting Center'},
      {'id': 7, 'kode': 'OUT_FOR_DELIVERY', 'nama_status': 'Sedang Diantar'},
      {'id': 8, 'kode': 'DELIVERED', 'nama_status': 'Berhasil Diterima'},
      {'id': 9, 'kode': 'FAILED_DELIVERY', 'nama_status': 'Pengantaran Gagal'},
      {'id': 10, 'kode': 'RETURNED', 'nama_status': 'Dikembalikan'},
      {'id': 11, 'kode': 'CANCELLED', 'nama_status': 'Dibatalkan'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select('id, kode, nama_layanan')
          .order('id', ascending: true);
      final list = List<Map<String, dynamic>>.from(res);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return [
      {'id': 1, 'kode': 'REG', 'nama_layanan': 'Reguler'},
      {'id': 2, 'kode': 'EXP', 'nama_layanan': 'Express / Kilat'},
      {'id': 3, 'kode': 'SD', 'nama_layanan': 'Same Day'},
      {'id': 4, 'kode': 'CARGO', 'nama_layanan': 'Cargo / Berat'},
    ];
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel(
      'admin_delivery_realtime_${DateTime.now().millisecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipments,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentAssignments,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentTracking,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentPayments,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentLocations,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    return channel;
  }

  static int _defaultStatusIdForCode(String code) {
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
        return 2;
    }
  }
}
