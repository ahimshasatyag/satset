import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

import '../../domain/entities/admin_report_detail.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';
import '../models/admin_report_detail_model.dart';
import '../models/admin_report_row_models.dart';

abstract class AdminReportRemoteDataSource {
  Future<bool> verifyAdminAccess();
  Future<AdminReportFilterReferences> getFilterReferences();
  Future<AdminReportDataResult> getReportData(AdminReportFilter filter);
  Future<AdminReportDetail> getReportDetail({
    required String reportType,
    required int recordId,
    AdminReportFilter? currentFilter,
  });
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminReportRemoteDataSourceImpl implements AdminReportRemoteDataSource {
  final SupabaseClient _client;

  AdminReportRemoteDataSourceImpl({SupabaseClient? client})
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
          final roleId =
              int.tryParse(empRes['id_users_role']?.toString() ?? '');
          final isActive = empRes['is_active'] != false;
          if (roleId == 1 && isActive) {
            return true;
          }
        }
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requireAdminAuthorization() async {
    final allowed = await verifyAdminAccess();
    if (!allowed) {
      throw Exception(
        'Akses Ditolak: Halaman Laporan hanya dapat diakses oleh Administrator resmi (m_employee.id_users_role = 1).',
      );
    }
  }

  @override
  Future<AdminReportFilterReferences> getFilterReferences() async {
    await _requireAdminAuthorization();

    final statuses = <AdminReportFilterReference>[];
    final services = <AdminReportFilterReference>[];
    final couriers = <AdminReportFilterReference>[];

    try {
      final statusRes = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode, nama_status, urutan')
          .order('urutan', ascending: true);
      for (final row in (statusRes as List)) {
        final id = row['id']?.toString() ?? '';
        final code = (row['kode']?.toString() ?? '').toUpperCase();
        final label = row['nama_status']?.toString() ??
            AdminStatusHelper.getStatusLabel(code);
        if (code.isNotEmpty) {
          statuses.add(
            AdminReportFilterReference(id: id, code: code, label: label),
          );
        }
      }
    } catch (_) {}

    try {
      final serviceRes = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select('id, kode, nama_layanan')
          .order('id', ascending: true);
      for (final row in (serviceRes as List)) {
        final id = row['id']?.toString() ?? '';
        final code = (row['kode']?.toString() ?? '').toUpperCase();
        final label = row['nama_layanan']?.toString() ?? code;
        if (code.isNotEmpty) {
          services.add(
            AdminReportFilterReference(
              id: id,
              code: code,
              label: '$code - $label',
            ),
          );
        }
      }
    } catch (_) {}

    try {
      final courierRes = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, employee_code, nama_lengkap, id_users_role')
          .eq(EmployeeTableColumns.idUsersRole, 2)
          .order('nama_lengkap', ascending: true);
      for (final row in (courierRes as List)) {
        final id = row['id']?.toString() ?? '';
        final code = row['employee_code']?.toString() ?? 'KURIR-$id';
        final name = row['nama_lengkap']?.toString() ?? 'Kurir #$id';
        if (id.isNotEmpty) {
          couriers.add(
            AdminReportFilterReference(
              id: id,
              code: code,
              label: '$name ($code)',
            ),
          );
        }
      }
    } catch (_) {}

    return AdminReportFilterReferences(
      shipmentStatuses: statuses,
      serviceTypes: services,
      couriers: couriers,
    );
  }

  /// Helper untuk memeriksa apakah suatu DateTime berada dalam rentang filter
  bool _isWithinDateRange(
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return true;
    if (date == null) return false;

    final local = date.toLocal();
    if (startDate != null) {
      final startBound = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      if (local.isBefore(startBound)) return false;
    }
    if (endDate != null) {
      final endBound = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      if (local.isAfter(endBound)) return false;
    }
    return true;
  }

  String _normalizePaymentStatus(String? rawStatus) {
    final s = (rawStatus ?? 'PENDING').trim().toUpperCase();
    if (s == 'PAID' || s == 'SETTLEMENT' || s == 'SUCCESS' || s == 'LUNAS') {
      return 'PAID';
    }
    if (s == 'EXPIRED' || s == 'KEDALUWARSA') {
      return 'EXPIRED';
    }
    if (s == 'FAILED' || s == 'DENY' || s == 'GAGAL') {
      return 'FAILED';
    }
    if (s == 'CANCELLED' || s == 'CANCEL') {
      return 'CANCELLED';
    }
    return 'PENDING';
  }

  bool _isDeliveredStatus(String statusCode) =>
      statusCode.toUpperCase() == 'DELIVERED';

  bool _isFailedStatus(String statusCode) =>
      statusCode.toUpperCase() == 'FAILED_DELIVERY';

  bool _isReturnedStatus(String statusCode) =>
      statusCode.toUpperCase() == 'RETURNED';

  bool _isCancelledStatus(String statusCode) =>
      statusCode.toUpperCase() == 'CANCELLED';

  bool _isInProcessStatus(String statusCode) {
    final c = statusCode.toUpperCase();
    return c != 'DELIVERED' &&
        c != 'FAILED_DELIVERY' &&
        c != 'RETURNED' &&
        c != 'CANCELLED';
  }

  @override
  Future<AdminReportDataResult> getReportData(AdminReportFilter filter) async {
    await _requireAdminAuthorization();

    final dateError = filter.validateDateRange();
    if (dateError != null) {
      throw Exception(dateError);
    }

    // 1. Ambil tabel referensi m_shipment_statuses & m_service_types
    final Map<int, Map<String, dynamic>> statusById = {};
    try {
      final statusRows = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode, nama_status, urutan, is_final');
      for (final s in (statusRows as List)) {
        final id = int.tryParse(s['id']?.toString() ?? '');
        if (id != null) {
          statusById[id] = Map<String, dynamic>.from(s as Map);
        }
      }
    } catch (_) {}

    final Map<int, Map<String, dynamic>> serviceById = {};
    try {
      final serviceRows = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select('id, kode, nama_layanan, estimasi_hari_min, estimasi_hari_max');
      for (final sv in (serviceRows as List)) {
        final id = int.tryParse(sv['id']?.toString() ?? '');
        if (id != null) {
          serviceById[id] = Map<String, dynamic>.from(sv as Map);
        }
      }
    } catch (_) {}

    // 2. Ambil data kurir dari m_employee (id_users_role = 2)
    final Map<int, Map<String, dynamic>> courierById = {};
    try {
      final empRows = await _client
          .from(DatabaseConstants.tableEmployee)
          .select(
            'id, employee_code, nama_lengkap, email, no_hp, id_users_role, is_active, created_at',
          )
          .eq(EmployeeTableColumns.idUsersRole, 2);
      for (final emp in (empRows as List)) {
        final id = int.tryParse(emp['id']?.toString() ?? '');
        if (id != null) {
          courierById[id] = Map<String, dynamic>.from(emp as Map);
        }
      }
    } catch (_) {}

    // 3. Ambil data pelanggan dari m_users (tanpa kolom sensitif password/token)
    final Map<int, Map<String, dynamic>> customerById = {};
    try {
      final userRows = await _client
          .from(DatabaseConstants.tableUsers)
          .select(
            'id, nama_lengkap, email, no_hp, email_verified, id_users_role, created_at',
          );
      for (final u in (userRows as List)) {
        final roleId = int.tryParse(u['id_users_role']?.toString() ?? '3') ?? 3;
        if (roleId == 3) {
          final id = int.tryParse(u['id']?.toString() ?? '');
          if (id != null) {
            customerById[id] = Map<String, dynamic>.from(u as Map);
          }
        }
      }
    } catch (_) {}

    // 4. Ambil data pengiriman t_shipments
    List<Map<String, dynamic>> rawShipments = [];
    try {
      var query = _client.from(DatabaseConstants.tableShipments).select('*');
      if (filter.startDate != null) {
        final startIso = DateTime(
          filter.startDate!.year,
          filter.startDate!.month,
          filter.startDate!.day,
        ).toUtc().toIso8601String();
        query = query.gte(ShipmentTableColumns.createdAt, startIso);
      }
      if (filter.endDate != null) {
        final endIso = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
          23,
          59,
          59,
        ).toUtc().toIso8601String();
        query = query.lte(ShipmentTableColumns.createdAt, endIso);
      }
      final res = await query.order(
        ShipmentTableColumns.createdAt,
        ascending: false,
      );
      rawShipments = List<Map<String, dynamic>>.from(res);
    } catch (_) {}

    // 5. Ambil penugasan kurir (t_shipment_assignments)
    List<Map<String, dynamic>> rawAssignments = [];
    final Map<int, Map<String, dynamic>> activeAssignmentByShipmentId = {};
    try {
      final assignRes = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select(
            'id, shipment_id, courier_id, assigned_by, assigned_at, accepted_at, completed_at, unassigned_at, catatan',
          )
          .order('assigned_at', ascending: false);
      rawAssignments = List<Map<String, dynamic>>.from(assignRes);
      for (final a in rawAssignments) {
        final sId = int.tryParse(a['shipment_id']?.toString() ?? '');
        if (sId != null &&
            a['unassigned_at'] == null &&
            !activeAssignmentByShipmentId.containsKey(sId)) {
          activeAssignmentByShipmentId[sId] = a;
        }
      }
    } catch (_) {}

    // 6. Ambil transaksi pembayaran (t_shipment_payments)
    List<Map<String, dynamic>> rawPayments = [];
    final Map<int, Map<String, dynamic>> latestPaymentByShipmentId = {};
    try {
      final payRes = await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .select('*')
          .order(ShipmentPaymentTableColumns.createdAt, ascending: false);
      rawPayments = List<Map<String, dynamic>>.from(payRes);
      for (final p in rawPayments) {
        final sId = int.tryParse(p['shipment_id']?.toString() ?? '');
        if (sId != null && !latestPaymentByShipmentId.containsKey(sId)) {
          latestPaymentByShipmentId[sId] = p;
        }
      }
    } catch (_) {}

    // 7. Ambil ringkasan jejak pelacakan (t_shipment_tracking), bukti kirim (t_shipment_proofs), dan lokasi GPS (t_shipment_locations)
    final Map<int, int> trackingCountByShipmentId = {};
    final Map<int, int> trackingCountByCourierId = {};
    try {
      final trackRes = await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .select('id, shipment_id, employee_id, created_at');
      for (final t in (trackRes as List)) {
        final sId = int.tryParse(t['shipment_id']?.toString() ?? '');
        final empId = int.tryParse(t['employee_id']?.toString() ?? '');
        if (sId != null) {
          trackingCountByShipmentId[sId] =
              (trackingCountByShipmentId[sId] ?? 0) + 1;
        }
        if (empId != null) {
          trackingCountByCourierId[empId] =
              (trackingCountByCourierId[empId] ?? 0) + 1;
        }
      }
    } catch (_) {}

    final Set<int> shipmentIdsWithProof = {};
    final Map<int, int> proofCountByCourierId = {};
    try {
      final proofRes = await _client
          .from(DatabaseConstants.tableShipmentProofs)
          .select('id, shipment_id, courier_id, created_at');
      for (final pf in (proofRes as List)) {
        final sId = int.tryParse(pf['shipment_id']?.toString() ?? '');
        final cId = int.tryParse(pf['courier_id']?.toString() ?? '');
        if (sId != null) shipmentIdsWithProof.add(sId);
        if (cId != null) {
          proofCountByCourierId[cId] = (proofCountByCourierId[cId] ?? 0) + 1;
        }
      }
    } catch (_) {}

    final Map<int, int> gpsCountByCourierId = {};
    final Map<int, DateTime> lastGpsByCourierId = {};
    try {
      final locRes = await _client
          .from(DatabaseConstants.tableShipmentLocations)
          .select('id, courier_id, recorded_at');
      for (final loc in (locRes as List)) {
        final cId = int.tryParse(loc['courier_id']?.toString() ?? '');
        if (cId != null) {
          gpsCountByCourierId[cId] = (gpsCountByCourierId[cId] ?? 0) + 1;
          final dt = loc['recorded_at'] != null
              ? DateTime.tryParse(loc['recorded_at'].toString())
              : null;
          if (dt != null) {
            final prev = lastGpsByCourierId[cId];
            if (prev == null || dt.isAfter(prev)) {
              lastGpsByCourierId[cId] = dt;
            }
          }
        }
      }
    } catch (_) {}

    // 8. Bangun seluruh baris Shipment yang memenuhi filter lintas dimensi
    final allShipmentRows = <AdminShipmentReportRowModel>[];
    final Map<int, Map<String, dynamic>> rawShipmentById = {};

    for (final s in rawShipments) {
      final sId = int.tryParse(s['id']?.toString() ?? '') ?? 0;
      if (sId <= 0) continue;
      rawShipmentById[sId] = s;

      final statusId = int.tryParse(
        (s['current_status_id'] ?? s['status_id'])?.toString() ?? '',
      );
      final serviceId = int.tryParse(s['service_type_id']?.toString() ?? '');
      final customerId = int.tryParse(s['customer_id']?.toString() ?? '');
      final activeAssign = activeAssignmentByShipmentId[sId];
      final assignedCourierId =
          int.tryParse(activeAssign?['courier_id']?.toString() ?? '');
      final courierMap =
          assignedCourierId != null ? courierById[assignedCourierId] : null;
      final paymentMap = latestPaymentByShipmentId[sId];

      final rowModel = AdminShipmentReportRowModel.fromRawMaps(
        shipmentMap: s,
        statusMap: statusId != null ? statusById[statusId] : null,
        serviceMap: serviceId != null ? serviceById[serviceId] : null,
        customerMap: customerId != null ? customerById[customerId] : null,
        courierMap: courierMap,
        paymentMap: paymentMap,
        trackingCount: trackingCountByShipmentId[sId] ?? 0,
        hasProof: shipmentIdsWithProof.contains(sId),
      );

      // Terapkan filter dimensi umum (tanggal, status pengiriman, layanan, metode bayar, status bayar, kurir)
      if (!_isWithinDateRange(
        rowModel.createdAt,
        filter.startDate,
        filter.endDate,
      )) {
        continue;
      }

      if (filter.shipmentStatusCode != null &&
          filter.shipmentStatusCode!.isNotEmpty &&
          filter.shipmentStatusCode != 'ALL') {
        if (rowModel.statusKode.toUpperCase() !=
            filter.shipmentStatusCode!.toUpperCase()) {
          continue;
        }
      }

      if (filter.serviceTypeCode != null &&
          filter.serviceTypeCode!.isNotEmpty &&
          filter.serviceTypeCode != 'ALL') {
        if (rowModel.serviceKode.toUpperCase() !=
            filter.serviceTypeCode!.toUpperCase()) {
          continue;
        }
      }

      if (filter.paymentMethod != null &&
          filter.paymentMethod!.isNotEmpty &&
          filter.paymentMethod != 'ALL') {
        if (rowModel.metodePembayaran.toUpperCase() !=
            filter.paymentMethod!.toUpperCase()) {
          continue;
        }
      }

      if (filter.paymentStatus != null &&
          filter.paymentStatus!.isNotEmpty &&
          filter.paymentStatus != 'ALL') {
        final normPayStatus = _normalizePaymentStatus(rowModel.statusPembayaran);
        if (normPayStatus != filter.paymentStatus!.toUpperCase()) {
          continue;
        }
      }

      if (filter.courierId != null) {
        if (rowModel.courierId != filter.courierId) {
          continue;
        }
      }

      allShipmentRows.add(rowModel);
    }

    // 9. Hitung Ringkasan Pengiriman (AdminShipmentReportSummary)
    int deliveredPkg = 0;
    int inProcessPkg = 0;
    int failedPkg = 0;
    int cancelledPkg = 0;
    int returnedPkg = 0;
    num totalWeightGrams = 0;
    num totalShipmentRevenue = 0;
    final Map<String, int> exactStatusCounter = {};

    for (final r in allShipmentRows) {
      final code = r.statusKode.toUpperCase();
      exactStatusCounter[code] = (exactStatusCounter[code] ?? 0) + 1;
      totalWeightGrams += r.totalBeratGram;
      if (!_isCancelledStatus(code)) {
        totalShipmentRevenue += r.totalBiaya;
      }
      if (_isDeliveredStatus(code)) {
        deliveredPkg++;
      } else if (_isFailedStatus(code)) {
        failedPkg++;
      } else if (_isCancelledStatus(code)) {
        cancelledPkg++;
      } else if (_isReturnedStatus(code)) {
        returnedPkg++;
      } else {
        inProcessPkg++;
      }
    }

    final shipmentSummary = AdminShipmentReportSummary(
      totalPackages: allShipmentRows.length,
      deliveredCount: deliveredPkg,
      inProcessCount: inProcessPkg,
      failedCount: failedPkg,
      cancelledCount: cancelledPkg,
      returnedCount: returnedPkg,
      totalWeightGrams: totalWeightGrams,
      totalRevenue: totalShipmentRevenue,
      countByExactStatus: exactStatusCounter,
    );

    // 10. Bangun seluruh baris Laporan Performa Kurir (AdminCourierReportRowModel)
    final Map<int, List<AdminShipmentReportRowModel>> shipmentsByCourier = {};
    final Map<int, DateTime> lastAssignByCourier = {};

    for (final a in rawAssignments) {
      if (a['unassigned_at'] != null) continue;
      final cId = int.tryParse(a['courier_id']?.toString() ?? '');
      final assignAt = a['assigned_at'] != null
          ? DateTime.tryParse(a['assigned_at'].toString())
          : null;
      if (cId != null && assignAt != null) {
        final prev = lastAssignByCourier[cId];
        if (prev == null || assignAt.isAfter(prev)) {
          lastAssignByCourier[cId] = assignAt;
        }
      }
    }

    for (final sRow in allShipmentRows) {
      if (sRow.courierId != null) {
        shipmentsByCourier.putIfAbsent(sRow.courierId!, () => []).add(sRow);
      }
    }

    final allCourierRows = <AdminCourierReportRowModel>[];
    for (final entry in courierById.entries) {
      final cId = entry.key;
      if (filter.courierId != null && filter.courierId != cId) {
        continue;
      }
      final emp = entry.value;
      final cShipments = shipmentsByCourier[cId] ?? const [];

      int cDelivered = 0;
      int cInProgress = 0;
      int cFailedOrReturned = 0;
      int cCancelled = 0;
      num cCodHandled = 0;

      for (final sh in cShipments) {
        final st = sh.statusKode.toUpperCase();
        if (_isDeliveredStatus(st)) {
          cDelivered++;
          if (sh.metodePembayaran == 'COD') {
            cCodHandled += sh.totalBiaya;
          }
        } else if (_isFailedStatus(st) || _isReturnedStatus(st)) {
          cFailedOrReturned++;
        } else if (_isCancelledStatus(st)) {
          cCancelled++;
        } else if (_isInProcessStatus(st)) {
          cInProgress++;
        }
      }

      allCourierRows.add(
        AdminCourierReportRowModel(
          courierId: cId,
          employeeCode: emp['employee_code']?.toString() ?? 'KURIR-$cId',
          namaLengkap: emp['nama_lengkap']?.toString() ?? 'Kurir #$cId',
          email: emp['email']?.toString() ?? '-',
          noHp: emp['no_hp']?.toString() ?? '-',
          isActive: emp['is_active'] != false,
          totalAssigned: cShipments.length,
          deliveredCount: cDelivered,
          inProgressCount: cInProgress,
          failedOrReturnedCount: cFailedOrReturned,
          cancelledCount: cCancelled,
          trackingUpdatesCount: trackingCountByCourierId[cId] ?? 0,
          proofUploadedCount: proofCountByCourierId[cId] ?? 0,
          gpsLocationsCount: gpsCountByCourierId[cId] ?? 0,
          totalCodHandled: cCodHandled,
          lastAssignmentAt: lastAssignByCourier[cId],
          lastGpsRecordedAt: lastGpsByCourierId[cId],
        ),
      );
    }

    int totalAssignedAllCouriers = 0;
    int totalDeliveredAllCouriers = 0;
    int totalInProgressAllCouriers = 0;
    int totalFailedAllCouriers = 0;
    int totalProofsAllCouriers = 0;
    int totalGpsAllCouriers = 0;
    int activeCourierCount = 0;

    for (final cr in allCourierRows) {
      if (cr.isActive) activeCourierCount++;
      totalAssignedAllCouriers += cr.totalAssigned;
      totalDeliveredAllCouriers += cr.deliveredCount;
      totalInProgressAllCouriers += cr.inProgressCount;
      totalFailedAllCouriers += cr.failedOrReturnedCount;
      totalProofsAllCouriers += cr.proofUploadedCount;
      totalGpsAllCouriers += cr.gpsLocationsCount;
    }

    final courierSummary = AdminCourierReportSummary(
      totalCouriers: allCourierRows.length,
      activeCouriers: activeCourierCount,
      totalAssignedTasks: totalAssignedAllCouriers,
      deliveredTasks: totalDeliveredAllCouriers,
      inProgressTasks: totalInProgressAllCouriers,
      failedOrReturnedTasks: totalFailedAllCouriers,
      totalProofUploaded: totalProofsAllCouriers,
      totalGpsLogs: totalGpsAllCouriers,
    );

    // 11. Bangun seluruh baris Laporan Aktivitas Pelanggan (AdminCustomerReportRowModel)
    final Map<int, List<AdminShipmentReportRowModel>> shipmentsByCustomer = {};
    for (final sRow in allShipmentRows) {
      final rawS = rawShipmentById[sRow.shipmentId];
      final custId = int.tryParse(rawS?['customer_id']?.toString() ?? '');
      if (custId != null) {
        shipmentsByCustomer.putIfAbsent(custId, () => []).add(sRow);
      }
    }

    final allCustomerRows = <AdminCustomerReportRowModel>[];
    for (final entry in customerById.entries) {
      final custId = entry.key;
      final u = entry.value;
      final custShipments = shipmentsByCustomer[custId] ?? const [];

      // Jika ada filter pengiriman spesifik yang aktif (misal filter kurir/layanan/status),
      // tampilkan pelanggan yang memiliki transaksi sesuai filter atau seluruh pelanggan jika tanpa filter spesifik
      if (filter.hasActiveFilters &&
          filter.searchQuery.trim().isEmpty &&
          custShipments.isEmpty) {
        continue;
      }

      int custDelivered = 0;
      int custActive = 0;
      int custFailedOrCancelled = 0;
      int custTransfer = 0;
      int custCod = 0;
      num custTotalSpend = 0;
      num custPaidSpend = 0;
      DateTime? lastShipmentDate;

      for (final sh in custShipments) {
        final st = sh.statusKode.toUpperCase();
        if (_isDeliveredStatus(st)) {
          custDelivered++;
        } else if (_isFailedStatus(st) ||
            _isCancelledStatus(st) ||
            _isReturnedStatus(st)) {
          custFailedOrCancelled++;
        } else {
          custActive++;
        }

        if (sh.metodePembayaran == 'COD') {
          custCod++;
        } else {
          custTransfer++;
        }

        if (!_isCancelledStatus(st)) {
          custTotalSpend += sh.totalBiaya;
        }
        if (_normalizePaymentStatus(sh.statusPembayaran) == 'PAID') {
          custPaidSpend += sh.totalBiaya;
        }

        if (sh.createdAt != null) {
          if (lastShipmentDate == null ||
              sh.createdAt!.isAfter(lastShipmentDate)) {
            lastShipmentDate = sh.createdAt;
          }
        }
      }

      allCustomerRows.add(
        AdminCustomerReportRowModel(
          customerId: custId,
          namaLengkap: u['nama_lengkap']?.toString() ?? 'Pelanggan #$custId',
          email: u['email']?.toString() ?? '-',
          noHp: u['no_hp']?.toString() ?? '-',
          emailVerified: u['email_verified'] == true,
          registeredAt: u['created_at'] != null
              ? DateTime.tryParse(u['created_at'].toString())
              : null,
          totalShipments: custShipments.length,
          deliveredShipments: custDelivered,
          activeShipments: custActive,
          failedOrCancelledShipments: custFailedOrCancelled,
          transferPaymentsCount: custTransfer,
          codPaymentsCount: custCod,
          totalShippingSpend: custTotalSpend,
          paidShippingSpend: custPaidSpend,
          lastShipmentAt: lastShipmentDate,
        ),
      );
    }

    int transactingCustomerCount = 0;
    int verifiedCustomerCount = 0;
    int customerTotalShipments = 0;
    int customerCompletedShipments = 0;
    num customerTotalValue = 0;
    num customerPaidValue = 0;

    for (final cRow in allCustomerRows) {
      if (cRow.totalShipments > 0) transactingCustomerCount++;
      if (cRow.emailVerified) verifiedCustomerCount++;
      customerTotalShipments += cRow.totalShipments;
      customerCompletedShipments += cRow.deliveredShipments;
      customerTotalValue += cRow.totalShippingSpend;
      customerPaidValue += cRow.paidShippingSpend;
    }

    final customerSummary = AdminCustomerReportSummary(
      totalCustomers: allCustomerRows.length,
      transactingCustomers: transactingCustomerCount,
      verifiedCustomers: verifiedCustomerCount,
      totalShipments: customerTotalShipments,
      completedShipments: customerCompletedShipments,
      totalTransactionValue: customerTotalValue,
      paidTransactionValue: customerPaidValue,
    );

    // 12. Bangun seluruh baris Laporan Pembayaran (AdminPaymentReportRowModel)
    final allPaymentRows = <AdminPaymentReportRowModel>[];
    final Set<int> shipmentIdsWithPaymentRecord = {};

    for (final p in rawPayments) {
      final pId = int.tryParse(p['id']?.toString() ?? '') ?? 0;
      final sId = int.tryParse(p['shipment_id']?.toString() ?? '') ?? 0;
      if (sId > 0) shipmentIdsWithPaymentRecord.add(sId);

      final rawS = rawShipmentById[sId];
      if (rawS == null) {
        // Pengiriman tidak masuk rentang atau tidak ditemukan
        continue;
      }

      final createdAt = p['created_at'] != null
          ? DateTime.tryParse(p['created_at'].toString())
          : (rawS['created_at'] != null
              ? DateTime.tryParse(rawS['created_at'].toString())
              : null);

      if (!_isWithinDateRange(createdAt, filter.startDate, filter.endDate)) {
        continue;
      }

      final statusId = int.tryParse(
        (rawS['current_status_id'] ?? rawS['status_id'])?.toString() ?? '',
      );
      final serviceId = int.tryParse(rawS['service_type_id']?.toString() ?? '');
      final custId = int.tryParse(rawS['customer_id']?.toString() ?? '');
      final activeAssign = activeAssignmentByShipmentId[sId];
      final assignedCourierId =
          int.tryParse(activeAssign?['courier_id']?.toString() ?? '');

      final stMap = statusId != null ? statusById[statusId] : null;
      final svMap = serviceId != null ? serviceById[serviceId] : null;
      final custMap = custId != null ? customerById[custId] : null;
      final courMap =
          assignedCourierId != null ? courierById[assignedCourierId] : null;

      final shipmentStatusKode =
          (stMap?['kode']?.toString() ?? 'PENDING').toUpperCase();
      final shipmentStatusNama = stMap?['nama_status']?.toString() ??
          AdminStatusHelper.getStatusLabel(shipmentStatusKode);
      final serviceKode = (svMap?['kode']?.toString() ?? 'REG').toUpperCase();
      final serviceNama = svMap?['nama_layanan']?.toString() ?? 'Reguler';

      final metode = (p['metode_pembayaran']?.toString() ??
              rawS['metode_pembayaran']?.toString() ??
              'TRANSFER')
          .toUpperCase();
      final statusBayar = _normalizePaymentStatus(
        p['status_pembayaran']?.toString(),
      );

      // Terapkan filter dimensi
      if (filter.shipmentStatusCode != null &&
          filter.shipmentStatusCode!.isNotEmpty &&
          filter.shipmentStatusCode != 'ALL') {
        if (shipmentStatusKode != filter.shipmentStatusCode!.toUpperCase()) {
          continue;
        }
      }
      if (filter.serviceTypeCode != null &&
          filter.serviceTypeCode!.isNotEmpty &&
          filter.serviceTypeCode != 'ALL') {
        if (serviceKode != filter.serviceTypeCode!.toUpperCase()) {
          continue;
        }
      }
      if (filter.paymentMethod != null &&
          filter.paymentMethod!.isNotEmpty &&
          filter.paymentMethod != 'ALL') {
        if (metode != filter.paymentMethod!.toUpperCase()) {
          continue;
        }
      }
      if (filter.paymentStatus != null &&
          filter.paymentStatus!.isNotEmpty &&
          filter.paymentStatus != 'ALL') {
        if (statusBayar != filter.paymentStatus!.toUpperCase()) {
          continue;
        }
      }
      if (filter.courierId != null && assignedCourierId != filter.courierId) {
        continue;
      }

      final totalTagihan =
          num.tryParse(rawS['total_biaya']?.toString() ?? '') ?? 0;
      final jumlahBayar =
          num.tryParse(p['jumlah_bayar']?.toString() ?? '') ?? totalTagihan;

      allPaymentRows.add(
        AdminPaymentReportRowModel(
          paymentId: pId,
          shipmentId: sId,
          nomorPembayaran:
              p['nomor_pembayaran']?.toString() ?? 'PAY-${sId.toString().padLeft(4, '0')}',
          nomorResi: rawS['nomor_resi']?.toString() ?? 'RESI-$sId',
          customerNama: custMap?['nama_lengkap']?.toString() ??
              rawS['pengirim_nama']?.toString() ??
              'Pelanggan SatSet',
          serviceKode: serviceKode,
          serviceNama: serviceNama,
          shipmentStatusKode: shipmentStatusKode,
          shipmentStatusNama: shipmentStatusNama,
          courierNama: courMap?['nama_lengkap']?.toString(),
          metodePembayaran: metode,
          statusPembayaran: statusBayar,
          provider: p['provider']?.toString(),
          providerReference: p['provider_reference']?.toString(),
          totalBiayaShipment: totalTagihan,
          jumlahBayar: jumlahBayar,
          createdAt: createdAt,
          paidAt: p['paid_at'] != null
              ? DateTime.tryParse(p['paid_at'].toString())
              : null,
          expiredAt: p['expired_at'] != null
              ? DateTime.tryParse(p['expired_at'].toString())
              : null,
        ),
      );
    }

    // Sertakan pengiriman yang belum memiliki baris di t_shipment_payments agar laporan konsisten
    for (final sRow in allShipmentRows) {
      if (shipmentIdsWithPaymentRecord.contains(sRow.shipmentId)) continue;
      final normStatus = _normalizePaymentStatus(sRow.statusPembayaran);
      allPaymentRows.add(
        AdminPaymentReportRowModel(
          paymentId: sRow.shipmentId,
          shipmentId: sRow.shipmentId,
          nomorPembayaran: 'INV-${sRow.nomorResi}',
          nomorResi: sRow.nomorResi,
          customerNama: sRow.customerNama,
          serviceKode: sRow.serviceKode,
          serviceNama: sRow.serviceNama,
          shipmentStatusKode: sRow.statusKode,
          shipmentStatusNama: sRow.statusNama,
          courierNama: sRow.courierNama,
          metodePembayaran: sRow.metodePembayaran,
          statusPembayaran: normStatus,
          provider: sRow.metodePembayaran == 'COD' ? 'COD' : 'GATEWAY',
          providerReference: null,
          totalBiayaShipment: sRow.totalBiaya,
          jumlahBayar: sRow.totalBiaya,
          createdAt: sRow.createdAt,
          paidAt: sRow.deliveredAt,
          expiredAt: null,
        ),
      );
    }

    int payTransferCount = 0;
    num payTransferNominal = 0;
    int payCodCount = 0;
    num payCodNominal = 0;
    int payPaidCount = 0;
    num payPaidNominal = 0;
    int payPendingCount = 0;
    num payPendingNominal = 0;
    int payFailedCount = 0;
    num payFailedNominal = 0;
    int payExpiredCount = 0;
    num payExpiredNominal = 0;
    num payTotalNominal = 0;

    for (final pr in allPaymentRows) {
      payTotalNominal += pr.jumlahBayar;
      if (pr.metodePembayaran == 'COD') {
        payCodCount++;
        payCodNominal += pr.jumlahBayar;
      } else {
        payTransferCount++;
        payTransferNominal += pr.jumlahBayar;
      }

      switch (pr.statusPembayaran) {
        case 'PAID':
          payPaidCount++;
          payPaidNominal += pr.jumlahBayar;
          break;
        case 'EXPIRED':
          payExpiredCount++;
          payExpiredNominal += pr.jumlahBayar;
          break;
        case 'FAILED':
        case 'CANCELLED':
          payFailedCount++;
          payFailedNominal += pr.jumlahBayar;
          break;
        case 'PENDING':
        default:
          payPendingCount++;
          payPendingNominal += pr.jumlahBayar;
          break;
      }
    }

    final paymentSummary = AdminPaymentReportSummary(
      totalTransactions: allPaymentRows.length,
      totalNominal: payTotalNominal,
      transferCount: payTransferCount,
      transferNominal: payTransferNominal,
      codCount: payCodCount,
      codNominal: payCodNominal,
      paidCount: payPaidCount,
      paidNominal: payPaidNominal,
      pendingCount: payPendingCount,
      pendingNominal: payPendingNominal,
      failedCount: payFailedCount,
      failedNominal: payFailedNominal,
      expiredCount: payExpiredCount,
      expiredNominal: payExpiredNominal,
    );

    // 13. Terapkan Pencarian Kata Kunci, Pengurutan Kolom, Grafik, dan Paginasi sesuai Jenis Laporan Aktif
    final query = filter.searchQuery.trim().toLowerCase();

    switch (filter.reportType.toUpperCase()) {
      case AdminReportType.courier:
        final searchedCouriers = allCourierRows.where((r) {
          if (query.isEmpty) return true;
          return r.namaLengkap.toLowerCase().contains(query) ||
              r.employeeCode.toLowerCase().contains(query) ||
              r.email.toLowerCase().contains(query) ||
              r.noHp.toLowerCase().contains(query);
        }).toList();

        _sortCourierRows(
          searchedCouriers,
          filter.sortColumn,
          filter.sortAscending,
        );

        final totalCount = searchedCouriers.length;
        final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 9999);
        final safePage = filter.page.clamp(1, totalPages);
        final startIdx = (safePage - 1) * filter.pageSize;
        final pagedCouriers = startIdx < totalCount
            ? searchedCouriers.skip(startIdx).take(filter.pageSize).toList()
            : <AdminCourierReportRow>[];

        final distChart = _buildCourierDistributionChart(searchedCouriers);
        final secondaryChart = _buildCourierStatusBreakdownChart(courierSummary);
        final trendChart = _buildCourierComparisonChart(searchedCouriers);

        num totalCodFiltered = 0;
        int totalTasksFiltered = 0;
        for (final c in searchedCouriers) {
          totalCodFiltered += c.totalCodHandled;
          totalTasksFiltered += c.totalAssigned;
        }

        return AdminReportDataResult(
          reportType: AdminReportType.courier,
          appliedFilter: filter.copyWith(page: safePage),
          shipmentSummary: shipmentSummary,
          courierSummary: courierSummary,
          customerSummary: customerSummary,
          paymentSummary: paymentSummary,
          distributionChart: distChart,
          secondaryDistributionChart: secondaryChart,
          trendChart: trendChart,
          courierRows: pagedCouriers,
          allFilteredCourierRows: searchedCouriers,
          totalFilteredCount: totalCount,
          currentPage: safePage,
          pageSize: filter.pageSize,
          totalPages: totalPages,
          filteredTotalAmount: totalCodFiltered,
          filteredSecondaryTotal: totalTasksFiltered,
        );

      case AdminReportType.customer:
        final searchedCustomers = allCustomerRows.where((r) {
          if (query.isEmpty) return true;
          return r.namaLengkap.toLowerCase().contains(query) ||
              r.email.toLowerCase().contains(query) ||
              r.noHp.toLowerCase().contains(query);
        }).toList();

        _sortCustomerRows(
          searchedCustomers,
          filter.sortColumn,
          filter.sortAscending,
        );

        final totalCount = searchedCustomers.length;
        final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 9999);
        final safePage = filter.page.clamp(1, totalPages);
        final startIdx = (safePage - 1) * filter.pageSize;
        final pagedCustomers = startIdx < totalCount
            ? searchedCustomers.skip(startIdx).take(filter.pageSize).toList()
            : <AdminCustomerReportRow>[];

        final distChart = _buildCustomerVerificationChart(searchedCustomers);
        final secondaryChart =
            _buildCustomerPaymentPreferenceChart(searchedCustomers);
        final trendChart = _buildTopCustomersChart(searchedCustomers);

        num totalSpendFiltered = 0;
        int totalShipmentsFiltered = 0;
        for (final c in searchedCustomers) {
          totalSpendFiltered += c.totalShippingSpend;
          totalShipmentsFiltered += c.totalShipments;
        }

        return AdminReportDataResult(
          reportType: AdminReportType.customer,
          appliedFilter: filter.copyWith(page: safePage),
          shipmentSummary: shipmentSummary,
          courierSummary: courierSummary,
          customerSummary: customerSummary,
          paymentSummary: paymentSummary,
          distributionChart: distChart,
          secondaryDistributionChart: secondaryChart,
          trendChart: trendChart,
          customerRows: pagedCustomers,
          allFilteredCustomerRows: searchedCustomers,
          totalFilteredCount: totalCount,
          currentPage: safePage,
          pageSize: filter.pageSize,
          totalPages: totalPages,
          filteredTotalAmount: totalSpendFiltered,
          filteredSecondaryTotal: totalShipmentsFiltered,
        );

      case AdminReportType.payment:
        final searchedPayments = allPaymentRows.where((r) {
          if (query.isEmpty) return true;
          return r.nomorPembayaran.toLowerCase().contains(query) ||
              r.nomorResi.toLowerCase().contains(query) ||
              r.customerNama.toLowerCase().contains(query) ||
              r.metodePembayaran.toLowerCase().contains(query) ||
              (r.providerReference?.toLowerCase().contains(query) ?? false);
        }).toList();

        _sortPaymentRows(
          searchedPayments,
          filter.sortColumn,
          filter.sortAscending,
        );

        final totalCount = searchedPayments.length;
        final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 9999);
        final safePage = filter.page.clamp(1, totalPages);
        final startIdx = (safePage - 1) * filter.pageSize;
        final pagedPayments = startIdx < totalCount
            ? searchedPayments.skip(startIdx).take(filter.pageSize).toList()
            : <AdminPaymentReportRow>[];

        final distChart = _buildPaymentStatusChart(searchedPayments);
        final secondaryChart = _buildPaymentMethodChart(searchedPayments);
        final trendChart = _buildPaymentDailyTrendChart(searchedPayments);

        num totalPaidFiltered = 0;
        num totalTagihanFiltered = 0;
        for (final p in searchedPayments) {
          totalPaidFiltered += p.jumlahBayar;
          totalTagihanFiltered += p.totalBiayaShipment;
        }

        return AdminReportDataResult(
          reportType: AdminReportType.payment,
          appliedFilter: filter.copyWith(page: safePage),
          shipmentSummary: shipmentSummary,
          courierSummary: courierSummary,
          customerSummary: customerSummary,
          paymentSummary: paymentSummary,
          distributionChart: distChart,
          secondaryDistributionChart: secondaryChart,
          trendChart: trendChart,
          paymentRows: pagedPayments,
          allFilteredPaymentRows: searchedPayments,
          totalFilteredCount: totalCount,
          currentPage: safePage,
          pageSize: filter.pageSize,
          totalPages: totalPages,
          filteredTotalAmount: totalPaidFiltered,
          filteredSecondaryTotal: totalTagihanFiltered,
        );

      case AdminReportType.shipment:
      default:
        final searchedShipments = allShipmentRows.where((r) {
          if (query.isEmpty) return true;
          return r.nomorResi.toLowerCase().contains(query) ||
              r.customerNama.toLowerCase().contains(query) ||
              r.pengirimNama.toLowerCase().contains(query) ||
              r.pengirimKota.toLowerCase().contains(query) ||
              r.penerimaNama.toLowerCase().contains(query) ||
              r.penerimaKota.toLowerCase().contains(query) ||
              (r.courierNama?.toLowerCase().contains(query) ?? false);
        }).toList();

        _sortShipmentRows(
          searchedShipments,
          filter.sortColumn,
          filter.sortAscending,
        );

        final totalCount = searchedShipments.length;
        final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 9999);
        final safePage = filter.page.clamp(1, totalPages);
        final startIdx = (safePage - 1) * filter.pageSize;
        final pagedShipments = startIdx < totalCount
            ? searchedShipments.skip(startIdx).take(filter.pageSize).toList()
            : <AdminShipmentReportRow>[];

        final distChart = _buildShipmentStatusDistributionChart(
          searchedShipments,
          statusById,
        );
        final secondaryChart =
            _buildShipmentServiceDistributionChart(searchedShipments);
        final trendChart = _buildShipmentDailyTrendChart(searchedShipments);

        num totalBiayaFiltered = 0;
        num totalBeratFiltered = 0;
        for (final s in searchedShipments) {
          totalBiayaFiltered += s.totalBiaya;
          totalBeratFiltered += s.totalBeratGram;
        }

        return AdminReportDataResult(
          reportType: AdminReportType.shipment,
          appliedFilter: filter.copyWith(page: safePage),
          shipmentSummary: shipmentSummary,
          courierSummary: courierSummary,
          customerSummary: customerSummary,
          paymentSummary: paymentSummary,
          distributionChart: distChart,
          secondaryDistributionChart: secondaryChart,
          trendChart: trendChart,
          shipmentRows: pagedShipments,
          allFilteredShipmentRows: searchedShipments,
          totalFilteredCount: totalCount,
          currentPage: safePage,
          pageSize: filter.pageSize,
          totalPages: totalPages,
          filteredTotalAmount: totalBiayaFiltered,
          filteredSecondaryTotal: totalBeratFiltered,
        );
    }
  }

  void _sortShipmentRows(
    List<AdminShipmentReportRowModel> rows,
    String sortColumn,
    bool ascending,
  ) {
    rows.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'nomor_resi':
          cmp = a.nomorResi.compareTo(b.nomorResi);
          break;
        case 'customer':
          cmp = a.customerNama
              .toLowerCase()
              .compareTo(b.customerNama.toLowerCase());
          break;
        case 'layanan':
          cmp = a.serviceKode.compareTo(b.serviceKode);
          break;
        case 'status':
          cmp = a.statusNama.compareTo(b.statusNama);
          break;
        case 'berat':
          cmp = a.totalBeratGram.compareTo(b.totalBeratGram);
          break;
        case 'total_biaya':
          cmp = a.totalBiaya.compareTo(b.totalBiaya);
          break;
        case 'created_at':
        default:
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dA.compareTo(dB);
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }

  void _sortCourierRows(
    List<AdminCourierReportRowModel> rows,
    String sortColumn,
    bool ascending,
  ) {
    rows.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'nama':
          cmp = a.namaLengkap
              .toLowerCase()
              .compareTo(b.namaLengkap.toLowerCase());
          break;
        case 'delivered':
          cmp = a.deliveredCount.compareTo(b.deliveredCount);
          break;
        case 'in_progress':
          cmp = a.inProgressCount.compareTo(b.inProgressCount);
          break;
        case 'failed':
          cmp = a.failedOrReturnedCount.compareTo(b.failedOrReturnedCount);
          break;
        case 'completion_rate':
          cmp = a.completionRate.compareTo(b.completionRate);
          break;
        case 'total_assigned':
        default:
          cmp = a.totalAssigned.compareTo(b.totalAssigned);
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }

  void _sortCustomerRows(
    List<AdminCustomerReportRowModel> rows,
    String sortColumn,
    bool ascending,
  ) {
    rows.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'nama':
          cmp = a.namaLengkap
              .toLowerCase()
              .compareTo(b.namaLengkap.toLowerCase());
          break;
        case 'delivered':
          cmp = a.deliveredShipments.compareTo(b.deliveredShipments);
          break;
        case 'total_spend':
          cmp = a.totalShippingSpend.compareTo(b.totalShippingSpend);
          break;
        case 'last_shipment':
          final dA = a.lastShipmentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.lastShipmentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dA.compareTo(dB);
          break;
        case 'total_shipments':
        default:
          cmp = a.totalShipments.compareTo(b.totalShipments);
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }

  void _sortPaymentRows(
    List<AdminPaymentReportRowModel> rows,
    String sortColumn,
    bool ascending,
  ) {
    rows.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'nomor_pembayaran':
          cmp = a.nomorPembayaran.compareTo(b.nomorPembayaran);
          break;
        case 'nomor_resi':
          cmp = a.nomorResi.compareTo(b.nomorResi);
          break;
        case 'metode':
          cmp = a.metodePembayaran.compareTo(b.metodePembayaran);
          break;
        case 'status':
          cmp = a.statusPembayaran.compareTo(b.statusPembayaran);
          break;
        case 'jumlah_bayar':
          cmp = a.jumlahBayar.compareTo(b.jumlahBayar);
          break;
        case 'created_at':
        default:
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dA.compareTo(dB);
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }

  List<AdminReportChartPoint> _buildShipmentStatusDistributionChart(
    List<AdminShipmentReportRowModel> rows,
    Map<int, Map<String, dynamic>> statusById,
  ) {
    if (rows.isEmpty) return const [];
    final Map<String, int> countMap = {};
    final Map<String, num> amountMap = {};
    final Map<String, String> labelMap = {};

    for (final s in statusById.values) {
      final code = (s['kode']?.toString() ?? '').toUpperCase();
      final name = s['nama_status']?.toString() ?? code;
      if (code.isNotEmpty) labelMap[code] = name;
    }

    for (final r in rows) {
      final code = r.statusKode.toUpperCase();
      countMap[code] = (countMap[code] ?? 0) + 1;
      amountMap[code] = (amountMap[code] ?? 0) + r.totalBiaya;
      labelMap.putIfAbsent(code, () => r.statusNama);
    }

    final total = rows.length;
    final list = countMap.entries.map((e) {
      return AdminReportChartPoint(
        code: e.key,
        label: labelMap[e.key] ?? e.key,
        count: e.value,
        amount: amountMap[e.key] ?? 0,
        percentage: total > 0 ? (e.value / total) * 100.0 : 0.0,
      );
    }).toList();

    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  List<AdminReportChartPoint> _buildShipmentServiceDistributionChart(
    List<AdminShipmentReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    final Map<String, int> countMap = {};
    final Map<String, num> amountMap = {};
    final Map<String, String> labelMap = {};

    for (final r in rows) {
      final code = r.serviceKode.toUpperCase();
      countMap[code] = (countMap[code] ?? 0) + 1;
      amountMap[code] = (amountMap[code] ?? 0) + r.totalBiaya;
      labelMap[code] = '${r.serviceKode} - ${r.serviceNama}';
    }

    final total = rows.length;
    final list = countMap.entries.map((e) {
      return AdminReportChartPoint(
        code: e.key,
        label: labelMap[e.key] ?? e.key,
        count: e.value,
        amount: amountMap[e.key] ?? 0,
        percentage: total > 0 ? (e.value / total) * 100.0 : 0.0,
      );
    }).toList();

    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  List<AdminReportTrendPoint> _buildShipmentDailyTrendChart(
    List<AdminShipmentReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    final Map<String, List<AdminShipmentReportRowModel>> groupedByDate = {};
    for (final r in rows) {
      final dt = r.createdAt?.toLocal();
      if (dt == null) continue;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      groupedByDate.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = groupedByDate.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 10
        ? sortedKeys.sublist(sortedKeys.length - 10)
        : sortedKeys;

    return recentKeys.map((k) {
      final items = groupedByDate[k]!;
      int delivered = 0;
      int inProc = 0;
      num rev = 0;
      for (final item in items) {
        if (_isDeliveredStatus(item.statusKode)) {
          delivered++;
        } else if (_isInProcessStatus(item.statusKode)) {
          inProc++;
        }
        rev += item.totalBiaya;
      }
      final dt = DateTime.tryParse(k);
      final label = dt != null ? AdminDateFormatter.formatShortDate(dt) : k;
      return AdminReportTrendPoint(
        label: label,
        primaryCount: items.length,
        secondaryCount: delivered,
        tertiaryCount: inProc,
        totalAmount: rev,
      );
    }).toList();
  }

  List<AdminReportChartPoint> _buildCourierDistributionChart(
    List<AdminCourierReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    final totalTasks =
        rows.fold<int>(0, (sum, item) => sum + item.totalAssigned);
    final list = rows
        .map(
          (r) => AdminReportChartPoint(
            code: r.employeeCode,
            label: r.namaLengkap,
            count: r.totalAssigned,
            amount: r.totalCodHandled,
            percentage:
                totalTasks > 0 ? (r.totalAssigned / totalTasks) * 100.0 : 0.0,
          ),
        )
        .toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list.take(8).toList();
  }

  List<AdminReportChartPoint> _buildCourierStatusBreakdownChart(
    AdminCourierReportSummary summary,
  ) {
    final total = summary.totalAssignedTasks;
    if (total <= 0) return const [];
    return [
      AdminReportChartPoint(
        code: 'DELIVERED',
        label: 'Pengiriman Berhasil',
        count: summary.deliveredTasks,
        percentage: (summary.deliveredTasks / total) * 100.0,
      ),
      AdminReportChartPoint(
        code: 'IN_PROGRESS',
        label: 'Tugas Sedang Berjalan',
        count: summary.inProgressTasks,
        percentage: (summary.inProgressTasks / total) * 100.0,
      ),
      AdminReportChartPoint(
        code: 'FAILED_RETURNED',
        label: 'Gagal / Dikembalikan',
        count: summary.failedOrReturnedTasks,
        percentage: (summary.failedOrReturnedTasks / total) * 100.0,
      ),
    ];
  }

  List<AdminReportTrendPoint> _buildCourierComparisonChart(
    List<AdminCourierReportRowModel> rows,
  ) {
    final sorted = List<AdminCourierReportRowModel>.from(rows)
      ..sort((a, b) => b.totalAssigned.compareTo(a.totalAssigned));
    return sorted.take(8).map((c) {
      return AdminReportTrendPoint(
        label: c.namaLengkap,
        primaryCount: c.totalAssigned,
        secondaryCount: c.deliveredCount,
        tertiaryCount: c.inProgressCount,
        totalAmount: c.totalCodHandled,
      );
    }).toList();
  }

  List<AdminReportChartPoint> _buildCustomerVerificationChart(
    List<AdminCustomerReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    int verified = 0;
    int unverified = 0;
    num verifiedSpend = 0;
    num unverifiedSpend = 0;

    for (final r in rows) {
      if (r.emailVerified) {
        verified++;
        verifiedSpend += r.totalShippingSpend;
      } else {
        unverified++;
        unverifiedSpend += r.totalShippingSpend;
      }
    }
    final total = rows.length;
    return [
      AdminReportChartPoint(
        code: 'VERIFIED',
        label: 'Email Terverifikasi',
        count: verified,
        amount: verifiedSpend,
        percentage: total > 0 ? (verified / total) * 100.0 : 0.0,
      ),
      AdminReportChartPoint(
        code: 'UNVERIFIED',
        label: 'Belum Verifikasi',
        count: unverified,
        amount: unverifiedSpend,
        percentage: total > 0 ? (unverified / total) * 100.0 : 0.0,
      ),
    ];
  }

  List<AdminReportChartPoint> _buildCustomerPaymentPreferenceChart(
    List<AdminCustomerReportRowModel> rows,
  ) {
    int transferTotal = 0;
    int codTotal = 0;
    for (final r in rows) {
      transferTotal += r.transferPaymentsCount;
      codTotal += r.codPaymentsCount;
    }
    final sum = transferTotal + codTotal;
    if (sum <= 0) return const [];
    return [
      AdminReportChartPoint(
        code: 'TRANSFER',
        label: 'Transfer Payment Gateway',
        count: transferTotal,
        percentage: (transferTotal / sum) * 100.0,
      ),
      AdminReportChartPoint(
        code: 'COD',
        label: 'Cash on Delivery (COD)',
        count: codTotal,
        percentage: (codTotal / sum) * 100.0,
      ),
    ];
  }

  List<AdminReportTrendPoint> _buildTopCustomersChart(
    List<AdminCustomerReportRowModel> rows,
  ) {
    final sorted = List<AdminCustomerReportRowModel>.from(rows)
      ..sort((a, b) => b.totalShipments.compareTo(a.totalShipments));
    return sorted.take(8).map((c) {
      return AdminReportTrendPoint(
        label: c.namaLengkap,
        primaryCount: c.totalShipments,
        secondaryCount: c.deliveredShipments,
        tertiaryCount: c.activeShipments,
        totalAmount: c.totalShippingSpend,
      );
    }).toList();
  }

  List<AdminReportChartPoint> _buildPaymentStatusChart(
    List<AdminPaymentReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    final Map<String, int> countMap = {};
    final Map<String, num> amountMap = {};

    for (final r in rows) {
      final st = r.statusPembayaran;
      countMap[st] = (countMap[st] ?? 0) + 1;
      amountMap[st] = (amountMap[st] ?? 0) + r.jumlahBayar;
    }

    final total = rows.length;
    final labels = {
      'PAID': 'Berhasil / Lunas (PAID)',
      'PENDING': 'Menunggu Pembayaran (PENDING)',
      'FAILED': 'Gagal (FAILED)',
      'EXPIRED': 'Kedaluwarsa (EXPIRED)',
      'CANCELLED': 'Dibatalkan (CANCELLED)',
    };

    final list = countMap.entries.map((e) {
      return AdminReportChartPoint(
        code: e.key,
        label: labels[e.key] ?? e.key,
        count: e.value,
        amount: amountMap[e.key] ?? 0,
        percentage: total > 0 ? (e.value / total) * 100.0 : 0.0,
      );
    }).toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  List<AdminReportChartPoint> _buildPaymentMethodChart(
    List<AdminPaymentReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    int transferCount = 0;
    num transferAmt = 0;
    int codCount = 0;
    num codAmt = 0;

    for (final r in rows) {
      if (r.metodePembayaran == 'COD') {
        codCount++;
        codAmt += r.jumlahBayar;
      } else {
        transferCount++;
        transferAmt += r.jumlahBayar;
      }
    }

    final total = rows.length;
    return [
      AdminReportChartPoint(
        code: 'TRANSFER',
        label: 'Transfer (Payment Gateway)',
        count: transferCount,
        amount: transferAmt,
        percentage: total > 0 ? (transferCount / total) * 100.0 : 0.0,
      ),
      AdminReportChartPoint(
        code: 'COD',
        label: 'Cash on Delivery (COD)',
        count: codCount,
        amount: codAmt,
        percentage: total > 0 ? (codCount / total) * 100.0 : 0.0,
      ),
    ];
  }

  List<AdminReportTrendPoint> _buildPaymentDailyTrendChart(
    List<AdminPaymentReportRowModel> rows,
  ) {
    if (rows.isEmpty) return const [];
    final Map<String, List<AdminPaymentReportRowModel>> grouped = {};
    for (final r in rows) {
      final dt = r.createdAt?.toLocal();
      if (dt == null) continue;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 10
        ? sortedKeys.sublist(sortedKeys.length - 10)
        : sortedKeys;

    return recentKeys.map((k) {
      final list = grouped[k]!;
      int paid = 0;
      int pending = 0;
      num nominal = 0;
      for (final item in list) {
        if (item.statusPembayaran == 'PAID') {
          paid++;
        } else if (item.statusPembayaran == 'PENDING') {
          pending++;
        }
        nominal += item.jumlahBayar;
      }
      final dt = DateTime.tryParse(k);
      final label = dt != null ? AdminDateFormatter.formatShortDate(dt) : k;
      return AdminReportTrendPoint(
        label: label,
        primaryCount: list.length,
        secondaryCount: paid,
        tertiaryCount: pending,
        totalAmount: nominal,
      );
    }).toList();
  }

  @override
  Future<AdminReportDetail> getReportDetail({
    required String reportType,
    required int recordId,
    AdminReportFilter? currentFilter,
  }) async {
    await _requireAdminAuthorization();

    final effectiveFilter =
        currentFilter ?? AdminReportFilter(reportType: reportType);
    final currentData = await getReportData(effectiveFilter);

    switch (reportType.toUpperCase()) {
      case AdminReportType.courier:
        final courierRow = currentData.allFilteredCourierRows
            .where((c) => c.courierId == recordId)
            .firstOrNull;
        if (courierRow == null) {
          throw Exception('Data kurir #$recordId tidak ditemukan.');
        }

        final relatedShipments = currentData.allFilteredShipmentRows
            .where((s) => s.courierId == recordId)
            .map(
              (s) => AdminReportSupportingShipment(
                shipmentId: s.shipmentId,
                nomorResi: s.nomorResi,
                createdAt: s.createdAt,
                serviceKode: s.serviceKode,
                serviceNama: s.serviceNama,
                statusKode: s.statusKode,
                statusNama: s.statusNama,
                pengirimNama: s.pengirimNama,
                pengirimKota: s.pengirimKota,
                penerimaNama: s.penerimaNama,
                penerimaKota: s.penerimaKota,
                courierNama: s.courierNama,
                metodePembayaran: s.metodePembayaran,
                statusPembayaran: s.statusPembayaran,
                totalBiaya: s.totalBiaya,
                hasProof: s.hasDeliveryProof,
              ),
            )
            .toList();

        List<AdminReportLocationLog> courierLocs = [];
        try {
          final locRes = await _client
              .from(DatabaseConstants.tableShipmentLocations)
              .select('*')
              .eq('courier_id', recordId)
              .order('recorded_at', ascending: false)
              .limit(10);
          courierLocs = (locRes as List)
              .map(
                (e) => AdminReportLocationLogModel.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        } catch (_) {}

        List<AdminReportProofItem> courierProofs = [];
        try {
          final proofRes = await _client
              .from(DatabaseConstants.tableShipmentProofs)
              .select('*')
              .eq('courier_id', recordId)
              .order('created_at', ascending: false)
              .limit(10);
          courierProofs = (proofRes as List)
              .map(
                (e) => AdminReportProofItemModel.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        } catch (_) {}

        return AdminReportDetail(
          reportType: AdminReportType.courier,
          recordId: recordId,
          title: 'Detail Performa Kurir: ${courierRow.namaLengkap}',
          subtitle:
              'Kode Employee: ${courierRow.employeeCode} • Total Penugasan: ${courierRow.totalAssigned} Paket',
          courierRow: courierRow,
          relatedShipments: relatedShipments,
          locationLogs: courierLocs,
          deliveryProofs: courierProofs,
        );

      case AdminReportType.customer:
        final customerRow = currentData.allFilteredCustomerRows
            .where((c) => c.customerId == recordId)
            .firstOrNull;
        if (customerRow == null) {
          throw Exception('Data pelanggan #$recordId tidak ditemukan.');
        }

        // Ambil daftar pengiriman milik pelanggan ini
        List<AdminReportSupportingShipment> custShipments = [];
        try {
          final rawCustShipments = await _client
              .from(DatabaseConstants.tableShipments)
              .select('id')
              .eq('customer_id', recordId);
          final custShipmentIds = (rawCustShipments as List)
              .map((e) => int.tryParse(e['id']?.toString() ?? ''))
              .whereType<int>()
              .toSet();

          custShipments = currentData.allFilteredShipmentRows
              .where((s) => custShipmentIds.contains(s.shipmentId))
              .map(
                (s) => AdminReportSupportingShipment(
                  shipmentId: s.shipmentId,
                  nomorResi: s.nomorResi,
                  createdAt: s.createdAt,
                  serviceKode: s.serviceKode,
                  serviceNama: s.serviceNama,
                  statusKode: s.statusKode,
                  statusNama: s.statusNama,
                  pengirimNama: s.pengirimNama,
                  pengirimKota: s.pengirimKota,
                  penerimaNama: s.penerimaNama,
                  penerimaKota: s.penerimaKota,
                  courierNama: s.courierNama,
                  metodePembayaran: s.metodePembayaran,
                  statusPembayaran: s.statusPembayaran,
                  totalBiaya: s.totalBiaya,
                  hasProof: s.hasDeliveryProof,
                ),
              )
              .toList();
        } catch (_) {}

        return AdminReportDetail(
          reportType: AdminReportType.customer,
          recordId: recordId,
          title: 'Detail Aktivitas Pelanggan: ${customerRow.namaLengkap}',
          subtitle:
              'Email: ${customerRow.email} • Total Pengiriman: ${customerRow.totalShipments} Transaksi',
          customerRow: customerRow,
          relatedShipments: custShipments,
        );

      case AdminReportType.payment:
        final paymentRow = currentData.allFilteredPaymentRows
            .where((p) => p.paymentId == recordId || p.shipmentId == recordId)
            .firstOrNull;
        if (paymentRow == null) {
          throw Exception('Data transaksi pembayaran #$recordId tidak ditemukan.');
        }

        final linkedShipment = currentData.allFilteredShipmentRows
            .where((s) => s.shipmentId == paymentRow.shipmentId)
            .firstOrNull;

        final trackingList =
            await _fetchShipmentTracking(paymentRow.shipmentId);
        final proofsList = await _fetchShipmentProofs(paymentRow.shipmentId);

        return AdminReportDetail(
          reportType: AdminReportType.payment,
          recordId: recordId,
          title: 'Detail Laporan Pembayaran: ${paymentRow.nomorPembayaran}',
          subtitle:
              'Resi: ${paymentRow.nomorResi} • Metode: ${paymentRow.metodePembayaran} • Status: ${paymentRow.statusPembayaran}',
          paymentRow: paymentRow,
          shipmentRow: linkedShipment,
          trackingHistory: trackingList,
          deliveryProofs: proofsList,
        );

      case AdminReportType.shipment:
      default:
        final shipmentRow = currentData.allFilteredShipmentRows
            .where((s) => s.shipmentId == recordId)
            .firstOrNull;
        if (shipmentRow == null) {
          throw Exception('Data pengiriman #$recordId tidak ditemukan.');
        }

        final linkedPayment = currentData.allFilteredPaymentRows
            .where((p) => p.shipmentId == recordId)
            .firstOrNull;
        final trackingList = await _fetchShipmentTracking(recordId);
        final proofsList = await _fetchShipmentProofs(recordId);
        final locList = await _fetchShipmentLocations(recordId);

        return AdminReportDetail(
          reportType: AdminReportType.shipment,
          recordId: recordId,
          title: 'Detail Laporan Pengiriman: ${shipmentRow.nomorResi}',
          subtitle:
              'Layanan: ${shipmentRow.serviceKode} (${shipmentRow.serviceNama}) • Status: ${shipmentRow.statusNama}',
          shipmentRow: shipmentRow,
          paymentRow: linkedPayment,
          trackingHistory: trackingList,
          deliveryProofs: proofsList,
          locationLogs: locList,
        );
    }
  }

  Future<List<AdminReportTrackingEvent>> _fetchShipmentTracking(
    int shipmentId,
  ) async {
    try {
      final statusRows = await _client
          .from(DatabaseConstants.tableShipmentStatuses)
          .select('id, kode, nama_status');
      final Map<int, Map<String, dynamic>> statusById = {};
      for (final s in (statusRows as List)) {
        final id = int.tryParse(s['id']?.toString() ?? '');
        if (id != null) statusById[id] = Map<String, dynamic>.from(s as Map);
      }

      final empRows = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('id, nama_lengkap, employee_code');
      final Map<int, Map<String, dynamic>> empById = {};
      for (final e in (empRows as List)) {
        final id = int.tryParse(e['id']?.toString() ?? '');
        if (id != null) empById[id] = Map<String, dynamic>.from(e as Map);
      }

      final tracks = await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .select('*')
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false);

      return (tracks as List)
          .map(
            (t) => AdminReportTrackingEventModel.fromMap(
              Map<String, dynamic>.from(t as Map),
              statusById: statusById,
              employeeById: empById,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminReportProofItem>> _fetchShipmentProofs(
    int shipmentId,
  ) async {
    try {
      final proofs = await _client
          .from(DatabaseConstants.tableShipmentProofs)
          .select('*')
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false);
      return (proofs as List)
          .map(
            (p) => AdminReportProofItemModel.fromMap(
              Map<String, dynamic>.from(p as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminReportLocationLog>> _fetchShipmentLocations(
    int shipmentId,
  ) async {
    try {
      final locs = await _client
          .from(DatabaseConstants.tableShipmentLocations)
          .select('*')
          .eq('shipment_id', shipmentId)
          .order('recorded_at', ascending: false)
          .limit(10);
      return (locs as List)
          .map(
            (l) => AdminReportLocationLogModel.fromMap(
              Map<String, dynamic>.from(l as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel('admin_report_realtime_channel');

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
          table: DatabaseConstants.tableShipmentPayments,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentAssignments,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    return channel;
  }
}
