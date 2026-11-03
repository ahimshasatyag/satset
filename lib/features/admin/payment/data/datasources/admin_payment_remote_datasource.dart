import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

import '../../domain/entities/admin_payment_detail.dart';
import '../../domain/entities/admin_payment_item.dart';
import '../models/admin_payment_detail_model.dart';
import '../models/admin_payment_item_model.dart';

abstract class AdminPaymentRemoteDataSource {
  Future<bool> verifyAdminAccess();

  Future<AdminPaymentsPaginatedResult> getPaginatedPayments({
    String tabCategory = AdminPaymentTab.all,
    String? searchQuery,
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    num? minAmount,
    num? maxAmount,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminPaymentDetailModel> getPaymentDetail(int paymentId);

  Future<List<AdminBankReferenceModel>> getBankReferences();

  Future<String> reconcilePaymentStatus({
    required int paymentId,
    required int shipmentId,
    String? notes,
  });

  Future<void> confirmCodPaymentSettlement({
    required int paymentId,
    required int shipmentId,
    required num verifiedAmount,
    String? settlementReference,
    String? notes,
  });

  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminPaymentRemoteDataSourceImpl implements AdminPaymentRemoteDataSource {
  final SupabaseClient _client;

  AdminPaymentRemoteDataSourceImpl({SupabaseClient? client})
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

  Future<int?> _resolveCurrentAdminEmployeeId() async {
    try {
      final localDataSource = AdminAuthLocalDataSourceImpl();
      final savedAdmin = await localDataSource.getAdmin();
      final email =
          savedAdmin?.email ?? _client.auth.currentUser?.email ?? '';
      if (email.isNotEmpty) {
        final emp = await _client
            .from(DatabaseConstants.tableEmployee)
            .select('id')
            .eq('email', email)
            .maybeSingle();
        if (emp != null) {
          return int.tryParse(emp['id']?.toString() ?? '');
        }
      }
      if (savedAdmin != null) {
        return int.tryParse(savedAdmin.id);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<AdminBankReferenceModel>> getBankReferences() async {
    try {
      final jenisRows = await _client
          .from(DatabaseConstants.tableJenisBank)
          .select('id, nama_jenis, created_at');
      final jenisMap = <String, Map<String, dynamic>>{};
      for (final j in (jenisRows as List)) {
        final id = j['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          jenisMap[id] = Map<String, dynamic>.from(j as Map);
        }
      }

      final bankRows = await _client
          .from(DatabaseConstants.tableBank)
          .select('id, nm_bank, nmr_rekening, jenis_bank_id, created_at')
          .order(BankTableColumns.createdAt, ascending: true);

      final result = <AdminBankReferenceModel>[];
      for (final b in (bankRows as List)) {
        final bMap = Map<String, dynamic>.from(b as Map);
        final jId = bMap['jenis_bank_id']?.toString() ?? '';
        result.add(
          AdminBankReferenceModel.fromMap(
            bMap,
            jenisBankMap: jenisMap[jId],
          ),
        );
      }

      if (result.isNotEmpty) return result;

      // Jika m_bank belum terisi tetapi m_jenis_bank ada, petakan dari m_jenis_bank
      return jenisMap.values.map((j) {
        return AdminBankReferenceModel(
          bankId: (j['id'] ?? '').toString(),
          namaPemilik: 'SatSet Official',
          nomorRekening: '-',
          jenisBankId: (j['id'] ?? '').toString(),
          namaJenisBank: (j['nama_jenis'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AdminPaymentsPaginatedResult> getPaginatedPayments({
    String tabCategory = AdminPaymentTab.all,
    String? searchQuery,
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    num? minAmount,
    num? maxAmount,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Ambil referensi bank (m_bank & m_jenis_bank)
    final bankReferences = await getBankReferences();
    final bankByJenisId = <String, AdminBankReferenceModel>{};
    final jenisNameById = <String, String>{};
    for (final b in bankReferences) {
      if (b.jenisBankId.isNotEmpty) {
        bankByJenisId[b.jenisBankId] = b;
        jenisNameById[b.jenisBankId] = b.namaJenisBank;
      }
    }

    // Ambil juga m_jenis_bank langsung untuk jaga-jaga jika ada jenis_bank_id yang belum punya baris di m_bank
    try {
      final jenisRows = await _client
          .from(DatabaseConstants.tableJenisBank)
          .select('id, nama_jenis');
      for (final j in (jenisRows as List)) {
        final id = (j['id'] ?? '').toString();
        final nama = (j['nama_jenis'] ?? '').toString();
        if (id.isNotEmpty && nama.isNotEmpty) {
          jenisNameById[id] = nama;
        }
      }
    } catch (_) {}

    // 2. Ambil seluruh data t_shipment_payments
    List<Map<String, dynamic>> rawPayments = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .select()
          .order(ShipmentPaymentTableColumns.createdAt, ascending: false);
      rawPayments = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      rawPayments = [];
    }

    // 3. Ambil seluruh data t_shipments terkait
    final Map<int, Map<String, dynamic>> shipmentById = {};
    try {
      final shipRes = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
            ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan)
          ''')
          .order(ShipmentTableColumns.createdAt, ascending: false);
      for (final s in (shipRes as List)) {
        final sMap = Map<String, dynamic>.from(s as Map);
        final id = int.tryParse(sMap['id']?.toString() ?? '');
        if (id != null) {
          shipmentById[id] = sMap;
        }
      }
    } catch (_) {
      try {
        final shipSimple = await _client
            .from(DatabaseConstants.tableShipments)
            .select()
            .order(ShipmentTableColumns.createdAt, ascending: false);
        for (final s in (shipSimple as List)) {
          final sMap = Map<String, dynamic>.from(s as Map);
          final id = int.tryParse(sMap['id']?.toString() ?? '');
          if (id != null) {
            shipmentById[id] = sMap;
          }
        }
      } catch (_) {}
    }

    // 4. Ambil profil customer dari m_users
    final Map<int, Map<String, dynamic>> userById = {};
    try {
      final userRes = await _client
          .from(DatabaseConstants.tableUsers)
          .select('id, nama_lengkap, email, no_hp');
      for (final u in (userRes as List)) {
        final uMap = Map<String, dynamic>.from(u as Map);
        final id = int.tryParse(uMap['id']?.toString() ?? '');
        if (id != null) {
          userById[id] = uMap;
        }
      }
    } catch (_) {}

    // 5. Petakan seluruh item pembayaran
    final List<AdminPaymentItemModel> allItems = [];
    for (final pMap in rawPayments) {
      final sId = int.tryParse(pMap['shipment_id']?.toString() ?? '');
      final sMap = sId != null ? shipmentById[sId] : null;
      final cId = int.tryParse(sMap?['customer_id']?.toString() ?? '');
      final uMap = cId != null ? userById[cId] : null;
      final jId = pMap['jenis_bank_id']?.toString() ?? '';

      allItems.add(
        AdminPaymentItemModel.fromMap(
          pMap,
          shipmentMap: sMap,
          customerMap: uMap,
          bankRef: bankByJenisId[jId],
          fallbackJenisBankName: jenisNameById[jId],
        ),
      );
    }

    // 6. Hitung ringkasan statistik menyeluruh & tab counts dari seluruh transaksi aktual
    int paidCount = 0;
    num paidAmount = 0;
    int pendingCount = 0;
    num pendingAmount = 0;
    int failedCount = 0;
    num failedAmount = 0;
    int expiredCount = 0;
    num expiredAmount = 0;

    int codTotalCount = 0;
    num codTotalAmount = 0;
    int codSettledCount = 0;
    num codSettledAmount = 0;
    int codUnsettledCount = 0;
    num codUnsettledAmount = 0;

    num totalAmount = 0;

    final methodCountMap = <String, int>{};
    final methodAmountMap = <String, num>{};
    final statusCountMap = <String, int>{};
    final statusAmountMap = <String, num>{};

    for (final item in allItems) {
      totalAmount += item.jumlahBayar;

      final normStatus = item.normalizedStatus;
      if (normStatus == 'PAID') {
        paidCount++;
        paidAmount += item.jumlahBayar;
      } else if (normStatus == 'FAILED') {
        failedCount++;
        failedAmount += item.jumlahBayar;
      } else if (normStatus == 'EXPIRED') {
        expiredCount++;
        expiredAmount += item.jumlahBayar;
      } else {
        pendingCount++;
        pendingAmount += item.jumlahBayar;
      }

      if (item.isCod) {
        codTotalCount++;
        codTotalAmount += item.jumlahBayar;
        if (item.isPaid) {
          codSettledCount++;
          codSettledAmount += item.jumlahBayar;
        } else {
          codUnsettledCount++;
          codUnsettledAmount += item.jumlahBayar;
        }
      }

      final mKey = item.metodePembayaran.isEmpty
          ? 'TRANSFER'
          : item.metodePembayaran.toUpperCase();
      methodCountMap[mKey] = (methodCountMap[mKey] ?? 0) + 1;
      methodAmountMap[mKey] = (methodAmountMap[mKey] ?? 0) + item.jumlahBayar;

      final sKey = item.isCod && !item.isPaid ? 'COD' : normStatus;
      statusCountMap[sKey] = (statusCountMap[sKey] ?? 0) + 1;
      statusAmountMap[sKey] = (statusAmountMap[sKey] ?? 0) + item.jumlahBayar;
    }

    final totalCountAll = allItems.length;

    final methodDist = methodCountMap.entries.map((e) {
      final pct =
          totalCountAll > 0 ? (e.value / totalCountAll) * 100.0 : 0.0;
      return AdminPaymentDistributionItem(
        code: e.key,
        label: _formatMethodLabel(e.key),
        count: e.value,
        totalAmount: methodAmountMap[e.key] ?? 0,
        percentage: double.parse(pct.toStringAsFixed(1)),
      );
    }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final statusDist = statusCountMap.entries.map((e) {
      final pct =
          totalCountAll > 0 ? (e.value / totalCountAll) * 100.0 : 0.0;
      return AdminPaymentDistributionItem(
        code: e.key,
        label: AdminStatusHelper.getPaymentStatusLabel(e.key),
        count: e.value,
        totalAmount: statusAmountMap[e.key] ?? 0,
        percentage: double.parse(pct.toStringAsFixed(1)),
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final summaryStats = AdminPaymentSummaryStats(
      totalTransactions: totalCountAll,
      totalAmount: totalAmount,
      paidCount: paidCount,
      paidAmount: paidAmount,
      pendingCount: pendingCount,
      pendingAmount: pendingAmount,
      failedCount: failedCount,
      failedAmount: failedAmount,
      expiredCount: expiredCount,
      expiredAmount: expiredAmount,
      codTotalCount: codTotalCount,
      codTotalAmount: codTotalAmount,
      codSettledCount: codSettledCount,
      codSettledAmount: codSettledAmount,
      codUnsettledCount: codUnsettledCount,
      codUnsettledAmount: codUnsettledAmount,
      dailyTrends: _buildDailyTrends(allItems),
      weeklyTrends: _buildWeeklyTrends(allItems),
      monthlyTrends: _buildMonthlyTrends(allItems),
      methodDistribution: methodDist,
      statusDistribution: statusDist,
    );

    final tabCounts = <String, int>{
      AdminPaymentTab.all: totalCountAll,
      AdminPaymentTab.pending: pendingCount,
      AdminPaymentTab.paid: paidCount,
      AdminPaymentTab.failed: failedCount,
      AdminPaymentTab.expired: expiredCount,
      AdminPaymentTab.cod: codTotalCount,
    };

    // 7. Terapkan filter tab, pencarian, metode, status, bank, tanggal, dan nominal
    final filtered = allItems.where((item) {
      // Filter Tab
      switch (tabCategory) {
        case AdminPaymentTab.pending:
          if (item.normalizedStatus != 'PENDING') return false;
          break;
        case AdminPaymentTab.paid:
          if (!item.isPaid) return false;
          break;
        case AdminPaymentTab.failed:
          if (!item.isFailed) return false;
          break;
        case AdminPaymentTab.expired:
          if (!item.isExpired) return false;
          break;
        case AdminPaymentTab.cod:
          if (!item.isCod) return false;
          break;
        case AdminPaymentTab.all:
        default:
          break;
      }

      // Filter Metode Pembayaran
      if (methodFilter != null &&
          methodFilter.isNotEmpty &&
          methodFilter != 'ALL') {
        if (item.metodePembayaran.toUpperCase() !=
            methodFilter.toUpperCase()) {
          return false;
        }
      }

      // Filter Status Pembayaran
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'ALL') {
        final target = statusFilter.toUpperCase();
        if (target == 'COD') {
          if (!item.isCod) return false;
        } else if (item.normalizedStatus != target &&
            item.statusPembayaran.toUpperCase() != target) {
          return false;
        }
      }

      // Filter Jenis Bank (m_jenis_bank)
      if (jenisBankFilter != null &&
          jenisBankFilter.isNotEmpty &&
          jenisBankFilter != 'ALL') {
        final matchId = item.jenisBankId == jenisBankFilter;
        final matchName = (item.namaJenisBank ?? '').toUpperCase() ==
            jenisBankFilter.toUpperCase();
        final matchProvider = (item.provider ?? '')
            .toUpperCase()
            .contains(jenisBankFilter.toUpperCase());
        if (!matchId && !matchName && !matchProvider) {
          return false;
        }
      }

      // Filter Rentang Tanggal Transaksi
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

      // Filter Nominal Pembayaran
      if (minAmount != null && item.jumlahBayar < minAmount) {
        return false;
      }
      if (maxAmount != null && item.jumlahBayar > maxAmount) {
        return false;
      }

      // Pencarian: nomor resi, ID transaksi / nomor_pembayaran, nama customer, atau referensi gateway
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchId = item.id.toString().contains(q);
        final matchNoPay = item.nomorPembayaran.toLowerCase().contains(q);
        final matchResi = item.nomorResi.toLowerCase().contains(q);
        final matchCustomer = item.customerNama.toLowerCase().contains(q);
        final matchEmail = item.customerEmail.toLowerCase().contains(q);
        final matchProvider =
            (item.provider ?? '').toLowerCase().contains(q);
        final matchRef =
            (item.providerReference ?? '').toLowerCase().contains(q);
        final matchBank =
            (item.namaJenisBank ?? '').toLowerCase().contains(q);

        if (!matchId &&
            !matchNoPay &&
            !matchResi &&
            !matchCustomer &&
            !matchEmail &&
            !matchProvider &&
            !matchRef &&
            !matchBank) {
          return false;
        }
      }

      return true;
    }).toList();

    // 8. Pengurutan Kolom (Sorting)
    filtered.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'nomor_pembayaran':
          cmp = a.nomorPembayaran.compareTo(b.nomorPembayaran);
          break;
        case 'nomor_resi':
          cmp = a.nomorResi.compareTo(b.nomorResi);
          break;
        case 'customer_nama':
          cmp = a.customerNama
              .toLowerCase()
              .compareTo(b.customerNama.toLowerCase());
          break;
        case 'jumlah_bayar':
          cmp = a.jumlahBayar.compareTo(b.jumlahBayar);
          break;
        case 'status_pembayaran':
          cmp = a.normalizedStatus.compareTo(b.normalizedStatus);
          break;
        case 'paid_at':
          final pA = a.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final pB = b.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = pA.compareTo(pB);
          break;
        case 'created_at':
        default:
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dA.compareTo(dB);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });

    // 9. Paginasi
    final totalFiltered = filtered.length;
    final safePage = page < 1 ? 1 : page;
    final startIndex = (safePage - 1) * pageSize;
    final pagedItems = startIndex >= totalFiltered
        ? <AdminPaymentItemModel>[]
        : filtered.skip(startIndex).take(pageSize).toList();

    return AdminPaymentsPaginatedResult(
      items: pagedItems,
      totalCount: totalFiltered,
      currentPage: safePage,
      pageSize: pageSize,
      summaryStats: summaryStats,
      tabCounts: tabCounts,
      bankReferences: bankReferences,
    );
  }

  @override
  Future<AdminPaymentDetailModel> getPaymentDetail(int paymentId) async {
    final bankReferences = await getBankReferences();
    final bankByJenisId = <String, AdminBankReferenceModel>{};
    final jenisNameById = <String, String>{};
    for (final b in bankReferences) {
      if (b.jenisBankId.isNotEmpty) {
        bankByJenisId[b.jenisBankId] = b;
        jenisNameById[b.jenisBankId] = b.namaJenisBank;
      }
    }

    final paymentRow = await _client
        .from(DatabaseConstants.tableShipmentPayments)
        .select()
        .eq(ShipmentPaymentTableColumns.id, paymentId)
        .single();
    final pMap = Map<String, dynamic>.from(paymentRow as Map);

    final shipmentId =
        int.tryParse(pMap['shipment_id']?.toString() ?? '0') ?? 0;

    Map<String, dynamic> shipmentMap = {};
    if (shipmentId > 0) {
      try {
        final sRow = await _client
            .from(DatabaseConstants.tableShipments)
            .select('''
              *,
              ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
              ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan)
            ''')
            .eq(ShipmentTableColumns.id, shipmentId)
            .maybeSingle();
        if (sRow != null) {
          shipmentMap = Map<String, dynamic>.from(sRow as Map);
        }
      } catch (_) {}
    }

    Map<String, dynamic>? customerMap;
    final customerId =
        int.tryParse(shipmentMap['customer_id']?.toString() ?? '');
    if (customerId != null && customerId > 0) {
      try {
        final uRow = await _client
            .from(DatabaseConstants.tableUsers)
            .select('id, nama_lengkap, email, no_hp')
            .eq(UserTableColumns.id, customerId)
            .maybeSingle();
        if (uRow != null) {
          customerMap = Map<String, dynamic>.from(uRow as Map);
        }
      } catch (_) {}
    }

    // Ambil informasi kurir jika pengiriman memiliki penugasan (penting untuk COD)
    String? courierNama;
    String? courierNoHp;
    if (shipmentId > 0) {
      try {
        final assignRows = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('courier_id, assigned_at')
            .eq(ShipmentAssignmentTableColumns.shipmentId, shipmentId)
            .isFilter(ShipmentAssignmentTableColumns.unassignedAt, null)
            .order(ShipmentAssignmentTableColumns.assignedAt, ascending: false)
            .limit(1);
        if ((assignRows as List).isNotEmpty) {
          final cId = assignRows.first['courier_id'];
          if (cId != null) {
            final empRow = await _client
                .from(DatabaseConstants.tableEmployee)
                .select('nama_lengkap, no_hp')
                .eq(EmployeeTableColumns.id, cId)
                .maybeSingle();
            if (empRow != null) {
              courierNama = empRow['nama_lengkap']?.toString();
              courierNoHp = empRow['no_hp']?.toString();
            }
          }
        }
      } catch (_) {}
    }

    // Ambil riwayat audit & pelacakan dari t_shipment_tracking dan t_notifications
    final List<AdminPaymentAuditLog> auditLogs = [];
    if (shipmentId > 0) {
      try {
        final trackRows = await _client
            .from(DatabaseConstants.tableShipmentTracking)
            .select('''
              id,
              status_id,
              employee_id,
              lokasi_nama,
              catatan,
              event_source,
              created_at,
              ${DatabaseConstants.tableShipmentStatuses}(kode, nama_status)
            ''')
            .eq(ShipmentTrackingTableColumns.shipmentId, shipmentId)
            .order(ShipmentTrackingTableColumns.createdAt, ascending: false);

        for (final t in (trackRows as List)) {
          final tMap = Map<String, dynamic>.from(t as Map);
          final stMap = tMap['m_shipment_statuses'] is Map<String, dynamic>
              ? tMap['m_shipment_statuses'] as Map<String, dynamic>
              : <String, dynamic>{};
          final statusLabel = (stMap['nama_status'] ??
                  AdminStatusHelper.getStatusLabel(stMap['kode']?.toString()))
              .toString();
          auditLogs.add(
            AdminPaymentAuditLogModel.fromTrackingMap(
              tMap,
              statusLabel: statusLabel,
            ),
          );
        }
      } catch (_) {}

      try {
        final notifRows = await _client
            .from(DatabaseConstants.tableNotifications)
            .select('id, judul, pesan, tipe, created_at')
            .eq(NotificationTableColumns.shipmentId, shipmentId)
            .order(NotificationTableColumns.createdAt, ascending: false)
            .limit(10);

        for (final n in (notifRows as List)) {
          auditLogs.add(
            AdminPaymentAuditLogModel.fromNotificationMap(
              Map<String, dynamic>.from(n as Map),
            ),
          );
        }
      } catch (_) {}
    }

    auditLogs.sort((a, b) {
      final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dB.compareTo(dA);
    });

    final jId = pMap['jenis_bank_id']?.toString() ?? '';
    final paymentItem = AdminPaymentItemModel.fromMap(
      pMap,
      shipmentMap: shipmentMap,
      customerMap: customerMap,
      bankRef: bankByJenisId[jId],
      fallbackJenisBankName: jenisNameById[jId],
    );

    return AdminPaymentDetailModel.fromData(
      payment: paymentItem,
      shipmentMap: shipmentMap,
      courierNama: courierNama,
      courierNoHp: courierNoHp,
      availableBanks: bankReferences,
      auditLogs: auditLogs,
    );
  }

  @override
  Future<String> reconcilePaymentStatus({
    required int paymentId,
    required int shipmentId,
    String? notes,
  }) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang diizinkan melakukan rekonsiliasi pembayaran.',
      );
    }

    // 1. Coba panggil RPC backend Supabase terlebih dahulu jika tersedia
    try {
      final rpcRes = await _client.rpc(
        'reconcile_shipment_payment',
        params: {
          'p_payment_id': paymentId,
          'p_shipment_id': shipmentId,
          'p_notes': notes ?? 'Rekonsiliasi status pembayaran oleh Admin',
        },
      );
      if (rpcRes != null) {
        return rpcRes.toString();
      }
    } catch (_) {
      // Lanjutkan ke pemeriksaan & sinkronisasi tervalidasi pada tabel t_shipment_payments & t_shipments
    }

    // 2. Ambil data terbaru langsung dari database (proteksi idempotensi)
    final pRow = await _client
        .from(DatabaseConstants.tableShipmentPayments)
        .select()
        .eq(ShipmentPaymentTableColumns.id, paymentId)
        .single();
    final sRow = await _client
        .from(DatabaseConstants.tableShipments)
        .select('id, nomor_resi, status_id, total_biaya, customer_id')
        .eq(ShipmentTableColumns.id, shipmentId)
        .single();

    final currentStatus =
        (pRow['status_pembayaran'] ?? 'PENDING').toString().toUpperCase();
    final method =
        (pRow['metode_pembayaran'] ?? 'TRANSFER').toString().toUpperCase();
    final jumlahBayar =
        num.tryParse(pRow['jumlah_bayar']?.toString() ?? '0') ?? 0;
    final totalBiaya =
        num.tryParse(sRow['total_biaya']?.toString() ?? '0') ?? 0;
    final expiredAt = pRow['expired_at'] != null
        ? DateTime.tryParse(pRow['expired_at'].toString())
        : null;

    final now = DateTime.now();
    final adminEmpId = await _resolveCurrentAdminEmployeeId();
    String reconciliationResultMessage;

    // 3. Validasi kesesuaian nominal
    if ((jumlahBayar - totalBiaya).abs() >= 1.0 && totalBiaya > 0) {
      await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .update({
            ShipmentPaymentTableColumns.jumlahBayar: totalBiaya,
            ShipmentPaymentTableColumns.updatedAt: now.toIso8601String(),
          })
          .eq(ShipmentPaymentTableColumns.id, paymentId);
    }

    // 4. Evaluasi status aktual berdasarkan aturan bisnis & batas waktu
    if (currentStatus == 'PAID' || currentStatus == 'SUCCESS') {
      // Jika sudah PAID dari webhook gateway tetapi status pengiriman masih PENDING (1), sinkronkan ke CONFIRMED (2)
      final shipmentStatusId =
          int.tryParse(sRow['status_id']?.toString() ?? '1') ?? 1;
      if (shipmentStatusId == 1) {
        await _client
            .from(DatabaseConstants.tableShipments)
            .update({
              ShipmentTableColumns.statusId: 2,
              ShipmentTableColumns.updatedAt: now.toIso8601String(),
            })
            .eq(ShipmentTableColumns.id, shipmentId);
      }
      reconciliationResultMessage =
          'Transaksi #${pRow['nomor_pembayaran']} telah terverifikasi LUNAS (PAID) secara idempoten.';
    } else if (method != 'COD' &&
        expiredAt != null &&
        now.isAfter(expiredAt) &&
        currentStatus != 'EXPIRED') {
      await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .update({
            ShipmentPaymentTableColumns.statusPembayaran: 'EXPIRED',
            ShipmentPaymentTableColumns.updatedAt: now.toIso8601String(),
          })
          .eq(ShipmentPaymentTableColumns.id, paymentId);
      reconciliationResultMessage =
          'Transaksi #${pRow['nomor_pembayaran']} telah melewati batas waktu pembayaran dan diperbarui menjadi KEDALUWARSA (EXPIRED).';
    } else {
      reconciliationResultMessage =
          'Rekonsiliasi selesai: Status pembayaran #${pRow['nomor_pembayaran']} saat ini adalah $currentStatus dan nominal sesuai dengan tagihan pengiriman.';
    }

    // 5. Catat jejak audit ke t_shipment_tracking
    try {
      final currentShipmentStatusId =
          int.tryParse(sRow['status_id']?.toString() ?? '1') ?? 1;
      await _client.from(DatabaseConstants.tableShipmentTracking).insert({
        ShipmentTrackingTableColumns.shipmentId: shipmentId,
        ShipmentTrackingTableColumns.statusId: currentShipmentStatusId,
        ShipmentTrackingTableColumns.employeeId: ?adminEmpId,
        ShipmentTrackingTableColumns.lokasiNama: 'Sistem Rekonsiliasi Pembayaran',
        ShipmentTrackingTableColumns.catatan: notes != null && notes.trim().isNotEmpty
            ? '$reconciliationResultMessage | Catatan: ${notes.trim()}'
            : reconciliationResultMessage,
        ShipmentTrackingTableColumns.eventSource: 'ADMIN_PAYMENT_RECONCILIATION',
      });
    } catch (_) {}

    return reconciliationResultMessage;
  }

  @override
  Future<void> confirmCodPaymentSettlement({
    required int paymentId,
    required int shipmentId,
    required num verifiedAmount,
    String? settlementReference,
    String? notes,
  }) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang diizinkan mengonfirmasi penyelesaian COD.',
      );
    }

    // 1. Ambil baris pembayaran & pengiriman terkini untuk memastikan idempotensi dan metode COD
    final pRow = await _client
        .from(DatabaseConstants.tableShipmentPayments)
        .select()
        .eq(ShipmentPaymentTableColumns.id, paymentId)
        .single();
    final sRow = await _client
        .from(DatabaseConstants.tableShipments)
        .select('id, nomor_resi, status_id, total_biaya, customer_id, metode_pembayaran')
        .eq(ShipmentTableColumns.id, shipmentId)
        .single();

    final method = (pRow['metode_pembayaran'] ??
            sRow['metode_pembayaran'] ??
            '')
        .toString()
        .toUpperCase();
    final currentStatus =
        (pRow['status_pembayaran'] ?? '').toString().toUpperCase();

    if (method != 'COD' && currentStatus != 'COD') {
      throw Exception(
        'Konfirmasi manual ini hanya diizinkan untuk metode pembayaran COD (Cash on Delivery). Pembayaran Transfer hanya dapat dikonfirmasi melalui webhook payment gateway yang terverifikasi.',
      );
    }

    if (currentStatus == 'PAID' || currentStatus == 'SUCCESS') {
      throw Exception(
        'Proteksi Idempotensi: Transaksi COD #${pRow['nomor_pembayaran']} sudah berstatus LUNAS (PAID) dan tidak dapat diproses ulang.',
      );
    }

    final expectedAmount =
        num.tryParse(sRow['total_biaya']?.toString() ?? '0') ??
            (num.tryParse(pRow['jumlah_bayar']?.toString() ?? '0') ?? 0);

    if (expectedAmount > 0 && (verifiedAmount - expectedAmount).abs() >= 1.0) {
      throw Exception(
        'Validasi Nominal Gagal: Nominal setoran COD ($verifiedAmount) harus sesuai dengan total tagihan pengiriman ($expectedAmount).',
      );
    }

    final now = DateTime.now();
    final refCode = (settlementReference != null &&
            settlementReference.trim().isNotEmpty)
        ? settlementReference.trim()
        : 'COD-SETTLED-${now.millisecondsSinceEpoch}';

    // 2. Update status pembayaran COD pada t_shipment_payments menjadi PAID
    await _client
        .from(DatabaseConstants.tableShipmentPayments)
        .update({
          ShipmentPaymentTableColumns.statusPembayaran: 'PAID',
          ShipmentPaymentTableColumns.jumlahBayar: verifiedAmount,
          ShipmentPaymentTableColumns.providerReference: refCode,
          ShipmentPaymentTableColumns.paidAt: now.toIso8601String(),
          ShipmentPaymentTableColumns.updatedAt: now.toIso8601String(),
        })
        .eq(ShipmentPaymentTableColumns.id, paymentId);

    // 3. Catat audit ke t_shipment_tracking & t_notifications
    final adminEmpId = await _resolveCurrentAdminEmployeeId();
    final currentShipmentStatusId =
        int.tryParse(sRow['status_id']?.toString() ?? '1') ?? 1;
    final nomorResi = (sRow['nomor_resi'] ?? 'SST-$shipmentId').toString();

    try {
      await _client.from(DatabaseConstants.tableShipmentTracking).insert({
        ShipmentTrackingTableColumns.shipmentId: shipmentId,
        ShipmentTrackingTableColumns.statusId: currentShipmentStatusId,
        ShipmentTrackingTableColumns.employeeId: ?adminEmpId,
        ShipmentTrackingTableColumns.lokasiNama: 'Kasir / Rekonsiliasi COD Admin',
        ShipmentTrackingTableColumns.catatan:
            'Pembayaran COD untuk resi $nomorResi telah diverifikasi LUNAS (Ref: $refCode)${notes != null && notes.trim().isNotEmpty ? " - ${notes.trim()}" : ""}.',
        ShipmentTrackingTableColumns.eventSource: 'ADMIN_COD_SETTLEMENT',
      });
    } catch (_) {}

    final customerId = int.tryParse(sRow['customer_id']?.toString() ?? '');
    if (customerId != null && customerId > 0) {
      try {
        await _client.from(DatabaseConstants.tableNotifications).insert({
          NotificationTableColumns.userId: customerId,
          NotificationTableColumns.shipmentId: shipmentId,
          NotificationTableColumns.judul: 'Pembayaran COD Terverifikasi Lunas',
          NotificationTableColumns.pesan:
              'Pembayaran COD untuk pengiriman $nomorResi telah diterima dan diverifikasi lunas (Ref: $refCode).',
          NotificationTableColumns.tipe: 'PAYMENT',
          NotificationTableColumns.isRead: false,
        });
      } catch (_) {}
    }
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel(
      'admin_payment_channel_${DateTime.now().millisecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentPayments,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipments,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    return channel;
  }

  String _formatMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'TRANSFER':
        return 'Transfer Bank / Gateway';
      case 'COD':
        return 'Cash on Delivery (COD)';
      case 'QRIS':
        return 'QRIS';
      case 'VIRTUAL_ACCOUNT':
        return 'Virtual Account';
      case 'EWALLET':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  List<AdminPaymentTrendPoint> _buildDailyTrends(
    List<AdminPaymentItemModel> items,
  ) {
    final now = DateTime.now();
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final List<AdminPaymentTrendPoint> points = [];

    for (int i = 6; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      num totalAmt = 0;
      num paidAmt = 0;
      num pendingAmt = 0;
      num codAmt = 0;
      int txCount = 0;
      int pCount = 0;

      for (final item in items) {
        final d = item.createdAt;
        if (d != null &&
            d.year == targetDate.year &&
            d.month == targetDate.month &&
            d.day == targetDate.day) {
          txCount++;
          totalAmt += item.jumlahBayar;
          if (item.isPaid) {
            paidAmt += item.jumlahBayar;
            pCount++;
          } else if (item.isPending) {
            pendingAmt += item.jumlahBayar;
          }
          if (item.isCod) {
            codAmt += item.jumlahBayar;
          }
        }
      }

      final dayLabel =
          '${dayNames[targetDate.weekday - 1]} ${targetDate.day}/${targetDate.month}';
      points.add(
        AdminPaymentTrendPoint(
          label: dayLabel,
          totalAmount: totalAmt,
          paidAmount: paidAmt,
          pendingAmount: pendingAmt,
          codAmount: codAmt,
          transactionCount: txCount,
          paidCount: pCount,
        ),
      );
    }
    return points;
  }

  List<AdminPaymentTrendPoint> _buildWeeklyTrends(
    List<AdminPaymentItemModel> items,
  ) {
    final now = DateTime.now();
    final List<AdminPaymentTrendPoint> points = [];

    for (int w = 3; w >= 0; w--) {
      final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59)
          .subtract(Duration(days: w * 7));
      final weekStart = DateTime(weekEnd.year, weekEnd.month, weekEnd.day)
          .subtract(const Duration(days: 6));

      num totalAmt = 0;
      num paidAmt = 0;
      num pendingAmt = 0;
      num codAmt = 0;
      int txCount = 0;
      int pCount = 0;

      for (final item in items) {
        final d = item.createdAt;
        if (d != null && !d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
          txCount++;
          totalAmt += item.jumlahBayar;
          if (item.isPaid) {
            paidAmt += item.jumlahBayar;
            pCount++;
          } else if (item.isPending) {
            pendingAmt += item.jumlahBayar;
          }
          if (item.isCod) {
            codAmt += item.jumlahBayar;
          }
        }
      }

      final label =
          '${weekStart.day}/${weekStart.month}-${weekEnd.day}/${weekEnd.month}';
      points.add(
        AdminPaymentTrendPoint(
          label: label,
          totalAmount: totalAmt,
          paidAmount: paidAmt,
          pendingAmount: pendingAmt,
          codAmount: codAmt,
          transactionCount: txCount,
          paidCount: pCount,
        ),
      );
    }
    return points;
  }

  List<AdminPaymentTrendPoint> _buildMonthlyTrends(
    List<AdminPaymentItemModel> items,
  ) {
    final now = DateTime.now();
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final List<AdminPaymentTrendPoint> points = [];

    for (int m = 5; m >= 0; m--) {
      final targetMonth = DateTime(now.year, now.month - m, 1);
      num totalAmt = 0;
      num paidAmt = 0;
      num pendingAmt = 0;
      num codAmt = 0;
      int txCount = 0;
      int pCount = 0;

      for (final item in items) {
        final d = item.createdAt;
        if (d != null &&
            d.year == targetMonth.year &&
            d.month == targetMonth.month) {
          txCount++;
          totalAmt += item.jumlahBayar;
          if (item.isPaid) {
            paidAmt += item.jumlahBayar;
            pCount++;
          } else if (item.isPending) {
            pendingAmt += item.jumlahBayar;
          }
          if (item.isCod) {
            codAmt += item.jumlahBayar;
          }
        }
      }

      final label =
          '${monthNames[targetMonth.month - 1]} ${targetMonth.year.toString().substring(2)}';
      points.add(
        AdminPaymentTrendPoint(
          label: label,
          totalAmount: totalAmt,
          paidAmount: paidAmt,
          pendingAmount: pendingAmt,
          codAmount: codAmt,
          transactionCount: txCount,
          paidCount: pCount,
        ),
      );
    }
    return points;
  }
}

