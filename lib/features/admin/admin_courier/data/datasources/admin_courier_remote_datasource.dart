import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/auth/data/utils/password_hasher.dart';
import 'package:satset/features/auth/data/utils/validators.dart';

import '../../domain/entities/admin_courier_item.dart';
import '../models/admin_courier_detail_model.dart';
import '../models/admin_courier_item_model.dart';

abstract class AdminCourierRemoteDataSource {
  Future<bool> verifyAdminAccess();

  Future<AdminCouriersPaginatedResult> getPaginatedCouriers({
    String? searchQuery,
    String accountStatusFilter = 'ALL',
    String activityStatusFilter = 'ALL',
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminCourierDetailModel> getCourierDetail(int courierId);

  Future<AdminCourierItemModel> createCourierAccount({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    bool isActive = true,
  });

  Future<AdminCourierItemModel> updateCourierProfile({
    required int courierId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? fotoUrl,
    String? newPassword,
    required bool isActive,
  });

  Future<void> toggleCourierAccountStatus({
    required int courierId,
    required bool isActive,
  });

  Future<void> unassignCourierTask({
    required int assignmentId,
    required int shipmentId,
    String? reason,
  });

  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminCourierRemoteDataSourceImpl implements AdminCourierRemoteDataSource {
  final SupabaseClient _client;

  AdminCourierRemoteDataSourceImpl({SupabaseClient? client})
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

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requireAdminAuthorization() async {
    final isAuthorized = await verifyAdminAccess();
    if (!isAuthorized) {
      throw Exception(
        'Akses Ditolak: Tindakan ini hanya diizinkan untuk Administrator resmi (m_employee.id_users_role = 1).',
      );
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

  @override
  Future<AdminCouriersPaginatedResult> getPaginatedCouriers({
    String? searchQuery,
    String accountStatusFilter = 'ALL',
    String activityStatusFilter = 'ALL',
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Ambil seluruh pegawai kurir dari m_employee dengan id_users_role = 2
    List<Map<String, dynamic>> rawCouriers = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('*')
          .eq(EmployeeTableColumns.idUsersRole, 2)
          .order(EmployeeTableColumns.createdAt, ascending: false);
      rawCouriers = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      final res = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('*')
          .order(EmployeeTableColumns.createdAt, ascending: false);
      rawCouriers = List<Map<String, dynamic>>.from(res).where((row) {
        final r = int.tryParse(row['id_users_role']?.toString() ?? '2') ?? 2;
        return r == 2;
      }).toList();
    }

    if (rawCouriers.isEmpty) {
      return AdminCouriersPaginatedResult.empty;
    }

    final courierIds = rawCouriers
        .map((e) => int.tryParse(e['id']?.toString() ?? ''))
        .whereType<int>()
        .toList();

    // 2. Ambil seluruh penugasan kurir dari t_shipment_assignments beserta status pengiriman dari t_shipments + m_shipment_statuses
    final Map<int, int> activeCountByCourier = {};
    final Map<int, int> totalHandledByCourier = {};
    final Map<int, int> deliveredCountByCourier = {};
    final Map<int, int> failedCountByCourier = {};
    final Map<int, String> activeResiByShipmentId = {};

    if (courierIds.isNotEmpty) {
      try {
        final assignRes = await _client
            .from(DatabaseConstants.tableShipmentAssignments)
            .select('''
              id,
              shipment_id,
              courier_id,
              completed_at,
              unassigned_at,
              ${DatabaseConstants.tableShipments}(
                id,
                nomor_resi,
                status_id,
                ${DatabaseConstants.tableShipmentStatuses}(kode, nama_status)
              )
            ''')
            .inFilter('courier_id', courierIds);

        final Map<int, Set<int>> handledShipmentsSet = {};
        final Map<int, Set<int>> deliveredShipmentsSet = {};
        final Map<int, Set<int>> failedShipmentsSet = {};
        final Map<int, Set<int>> activeShipmentsSet = {};

        for (final row in (assignRes as List)) {
          final cId = int.tryParse(row['courier_id']?.toString() ?? '');
          final sId = int.tryParse(row['shipment_id']?.toString() ?? '');
          if (cId == null || sId == null) continue;

          handledShipmentsSet.putIfAbsent(cId, () => <int>{}).add(sId);

          final shipMap = row['t_shipments'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(row['t_shipments'] as Map)
              : <String, dynamic>{};
          final statusMap = shipMap['m_shipment_statuses'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(shipMap['m_shipment_statuses'] as Map)
              : <String, dynamic>{};
          final statusCode =
              (statusMap['kode'] ?? '').toString().toUpperCase();
          final resi = shipMap['nomor_resi']?.toString();
          if (resi != null && resi.isNotEmpty) {
            activeResiByShipmentId[sId] = resi;
          }

          if (statusCode == 'DELIVERED') {
            deliveredShipmentsSet.putIfAbsent(cId, () => <int>{}).add(sId);
          } else if (statusCode == 'FAILED_DELIVERY' ||
              statusCode == 'RETURNED') {
            failedShipmentsSet.putIfAbsent(cId, () => <int>{}).add(sId);
          }

          final isUnassigned = row['unassigned_at'] != null;
          final isCompleted = row['completed_at'] != null;
          final isTerminal = statusCode == 'DELIVERED' ||
              statusCode == 'CANCELLED' ||
              statusCode == 'RETURNED';

          if (!isUnassigned && !isCompleted && !isTerminal) {
            activeShipmentsSet.putIfAbsent(cId, () => <int>{}).add(sId);
          }
        }

        for (final cId in courierIds) {
          totalHandledByCourier[cId] = handledShipmentsSet[cId]?.length ?? 0;
          deliveredCountByCourier[cId] =
              deliveredShipmentsSet[cId]?.length ?? 0;
          failedCountByCourier[cId] = failedShipmentsSet[cId]?.length ?? 0;
          activeCountByCourier[cId] = activeShipmentsSet[cId]?.length ?? 0;
        }
      } catch (_) {}
    }

    // 3. Ambil lokasi terakhir dari t_shipment_locations untuk kurir yang sedang memiliki tugas aktif
    final Map<int, AdminCourierLastLocationModel> lastLocationByCourier = {};
    final activeCourierIds = courierIds
        .where((id) => (activeCountByCourier[id] ?? 0) > 0)
        .toList();

    if (activeCourierIds.isNotEmpty) {
      try {
        final locRes = await _client
            .from(DatabaseConstants.tableShipmentLocations)
            .select('*')
            .inFilter('courier_id', activeCourierIds)
            .order('recorded_at', ascending: false)
            .limit(100);

        for (final locRow in (locRes as List)) {
          final cId = int.tryParse(locRow['courier_id']?.toString() ?? '');
          final sId = int.tryParse(locRow['shipment_id']?.toString() ?? '');
          if (cId != null && !lastLocationByCourier.containsKey(cId)) {
            lastLocationByCourier[cId] = AdminCourierLastLocationModel.fromMap(
              Map<String, dynamic>.from(locRow as Map),
              nomorResi: sId != null ? activeResiByShipmentId[sId] : null,
            );
          }
        }
      } catch (_) {}
    }

    // 4. Konversi menjadi list AdminCourierItemModel
    final allCouriers = rawCouriers.map((row) {
      final cId = int.tryParse(row['id']?.toString() ?? '0') ?? 0;
      return AdminCourierItemModel.fromMap(
        row,
        activeTasksCount: activeCountByCourier[cId] ?? 0,
        totalHandledCount: totalHandledByCourier[cId] ?? 0,
        deliveredCount: deliveredCountByCourier[cId] ?? 0,
        failedCount: failedCountByCourier[cId] ?? 0,
        lastLocation: lastLocationByCourier[cId],
      );
    }).toList();

    // 5. Hitung Ringkasan Statistik Aktual seluruh kurir (m_employee id_users_role = 2)
    int activeAccountCount = 0;
    int inactiveAccountCount = 0;
    int withTaskCount = 0;
    int withoutTaskCount = 0;

    for (final c in allCouriers) {
      if (c.isActive) {
        activeAccountCount++;
      } else {
        inactiveAccountCount++;
      }
      if (c.hasActiveAssignment) {
        withTaskCount++;
      } else {
        withoutTaskCount++;
      }
    }

    final summaryStats = AdminCourierSummaryStats(
      totalCouriers: allCouriers.length,
      activeCouriers: activeAccountCount,
      inactiveCouriers: inactiveAccountCount,
      couriersWithActiveTask: withTaskCount,
      couriersWithoutActiveTask: withoutTaskCount,
    );

    // 6. Terapkan pencarian dan filter
    final q = (searchQuery ?? '').trim().toLowerCase();
    final filtered = allCouriers.where((c) {
      // Filter status akun
      if (accountStatusFilter == 'ACTIVE' && !c.isActive) return false;
      if (accountStatusFilter == 'INACTIVE' && c.isActive) return false;

      // Filter status aktivitas penugasan
      if (activityStatusFilter == 'ON_TASK' && !c.hasActiveAssignment) {
        return false;
      }
      if (activityStatusFilter == 'STANDBY' &&
          (c.hasActiveAssignment || !c.isActive)) {
        return false;
      }
      if (activityStatusFilter == 'UNASSIGNED' && c.hasActiveAssignment) {
        return false;
      }

      // Pencarian nama, email, nomor telepon, atau identitas employee
      if (q.isNotEmpty) {
        final matchName = c.namaLengkap.toLowerCase().contains(q);
        final matchEmail = c.email.toLowerCase().contains(q);
        final matchPhone = c.noHp.toLowerCase().contains(q);
        final matchCode = c.employeeCode.toLowerCase().contains(q);
        if (!matchName && !matchEmail && !matchPhone && !matchCode) {
          return false;
        }
      }

      return true;
    }).toList();

    // 7. Pengurutan berdasarkan nama atau tanggal bergabung atau beban tugas
    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'nama_lengkap':
          cmp = a.namaLengkap
              .toLowerCase()
              .compareTo(b.namaLengkap.toLowerCase());
          break;
        case 'employee_code':
          cmp = a.employeeCode
              .toLowerCase()
              .compareTo(b.employeeCode.toLowerCase());
          break;
        case 'active_tasks':
          cmp = a.activeTasksCount.compareTo(b.activeTasksCount);
          break;
        case 'total_handled':
          cmp = a.totalHandledCount.compareTo(b.totalHandledCount);
          break;
        case 'created_at':
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });

    // 8. Paginasi
    final totalFiltered = filtered.length;
    final safePage = page < 1 ? 1 : page;
    final startIndex = (safePage - 1) * pageSize;
    final pagedItems = startIndex >= totalFiltered
        ? <AdminCourierItemModel>[]
        : filtered.skip(startIndex).take(pageSize).toList();

    return AdminCouriersPaginatedResult(
      items: pagedItems,
      totalCount: totalFiltered,
      currentPage: safePage,
      pageSize: pageSize,
      summaryStats: summaryStats,
    );
  }

  @override
  Future<AdminCourierDetailModel> getCourierDetail(int courierId) async {
    await _requireAdminAuthorization();

    // 1. Ambil baris kurir dari m_employee
    final empRow = await _client
        .from(DatabaseConstants.tableEmployee)
        .select('*')
        .eq(EmployeeTableColumns.id, courierId)
        .maybeSingle();

    if (empRow == null) {
      throw Exception('Data kurir (ID: $courierId) tidak ditemukan pada tabel m_employee.');
    }

    // 2. Ambil seluruh riwayat penugasan kurir dari t_shipment_assignments + t_shipments + m_service_types + m_shipment_statuses
    List<AdminCourierAssignmentRecordModel> assignments = [];
    final Set<int> handledShipmentIds = {};
    final Set<int> deliveredShipmentIds = {};
    final Set<int> failedShipmentIds = {};
    final Set<int> activeShipmentIds = {};
    final Map<int, String> resiByShipmentId = {};

    try {
      final assignRes = await _client
          .from(DatabaseConstants.tableShipmentAssignments)
          .select('''
            *,
            ${DatabaseConstants.tableShipments}(
              *,
              ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
              ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan)
            )
          ''')
          .eq('courier_id', courierId)
          .order('assigned_at', ascending: false);

      for (final raw in (assignRes as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final record = AdminCourierAssignmentRecordModel.fromMap(map);
        assignments.add(record);

        if (record.shipmentId > 0) {
          handledShipmentIds.add(record.shipmentId);
          resiByShipmentId[record.shipmentId] = record.nomorResi;

          final code = record.statusKode.toUpperCase();
          if (code == 'DELIVERED') {
            deliveredShipmentIds.add(record.shipmentId);
          } else if (code == 'FAILED_DELIVERY' || code == 'RETURNED') {
            failedShipmentIds.add(record.shipmentId);
          }
          if (record.isActiveTask) {
            activeShipmentIds.add(record.shipmentId);
          }
        }
      }
    } catch (_) {}

    // 3. Ambil lokasi GPS terakhir dari t_shipment_locations apabila kurir sedang menjalankan tugas aktif
    AdminCourierLastLocationModel? lastLocation;
    if (activeShipmentIds.isNotEmpty) {
      try {
        final locRow = await _client
            .from(DatabaseConstants.tableShipmentLocations)
            .select('*')
            .eq('courier_id', courierId)
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (locRow != null) {
          final sId = int.tryParse(locRow['shipment_id']?.toString() ?? '');
          lastLocation = AdminCourierLastLocationModel.fromMap(
            Map<String, dynamic>.from(locRow),
            nomorResi: sId != null ? resiByShipmentId[sId] : null,
          );
        }
      } catch (_) {}
    }

    // 4. Ambil riwayat aktivitas kurir dari t_shipment_tracking
    List<AdminCourierActivityLogModel> activityLogs = [];
    try {
      final trackRes = await _client
          .from(DatabaseConstants.tableShipmentTracking)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(kode, nama_status),
            ${DatabaseConstants.tableShipments}(nomor_resi)
          ''')
          .eq('employee_id', courierId)
          .order('created_at', ascending: false)
          .limit(50);

      activityLogs = (trackRes as List).map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final sId = int.tryParse(map['shipment_id']?.toString() ?? '');
        return AdminCourierActivityLogModel.fromMap(
          map,
          nomorResiOverride: sId != null ? resiByShipmentId[sId] : null,
        );
      }).toList();
    } catch (_) {}

    final courierModel = AdminCourierItemModel.fromMap(
      Map<String, dynamic>.from(empRow),
      activeTasksCount: activeShipmentIds.length,
      totalHandledCount: handledShipmentIds.length,
      deliveredCount: deliveredShipmentIds.length,
      failedCount: failedShipmentIds.length,
      lastLocation: lastLocation,
    );

    return AdminCourierDetailModel.create(
      courier: courierModel,
      assignments: assignments,
      activityLogs: activityLogs,
    );
  }

  Future<String> _generateNextEmployeeCode() async {
    int maxCodeNum = 0;
    try {
      final employees = await _client
          .from(DatabaseConstants.tableEmployee)
          .select('employee_code')
          .order('id', ascending: false)
          .limit(100);

      for (final emp in (employees as List)) {
        final code = emp['employee_code']?.toString() ?? '';
        final match = RegExp(r'\d+').firstMatch(code);
        if (match != null) {
          final parsed = int.tryParse(match.group(0)!);
          if (parsed != null && parsed > maxCodeNum) {
            maxCodeNum = parsed;
          }
        }
      }
    } catch (_) {}

    return (maxCodeNum + 1).toString().padLeft(3, '0');
  }

  @override
  Future<AdminCourierItemModel> createCourierAccount({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    bool isActive = true,
  }) async {
    await _requireAdminAuthorization();

    final cleanName = namaLengkap.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = noHp.trim();
    final cleanAddress = alamatLengkap?.trim();
    final cleanFoto = fotoUrl?.trim();

    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final phoneError = Validators.validatePhone(cleanPhone);
    if (phoneError != null) throw Exception(phoneError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    // 1. Pastikan email belum dipakai pada m_employee maupun m_users
    final existingEmp = await _client
        .from(DatabaseConstants.tableEmployee)
        .select('id, email')
        .eq(EmployeeTableColumns.email, cleanEmail)
        .maybeSingle();
    if (existingEmp != null) {
      throw Exception('Email "$cleanEmail" sudah terdaftar pada tabel m_employee.');
    }

    final existingUser = await _client
        .from(DatabaseConstants.tableUsers)
        .select('id, email')
        .eq(UserTableColumns.email, cleanEmail)
        .maybeSingle();
    if (existingUser != null) {
      throw Exception(
        'Email "$cleanEmail" sudah digunakan oleh akun customer pada m_users.',
      );
    }

    // 2. Hash password dengan SHA-256 + salt (tidak pernah menyimpan plaintext password)
    final hashedPassword = PasswordHasher.hash(password);

    // 3. Tentukan employee_code
    String finalCode = (employeeCode ?? '').trim();
    if (finalCode.isEmpty) {
      finalCode = await _generateNextEmployeeCode();
    }

    // 4. Coba jalankan RPC backend apabila tersedia untuk pembuatan akun tervalidasi
    try {
      final rpcRes = await _client.rpc(
        'rpc_admin_create_courier',
        params: {
          'p_employee_code': finalCode,
          'p_nama_lengkap': cleanName,
          'p_email': cleanEmail,
          'p_no_hp': cleanPhone,
          'p_password_hash': hashedPassword,
          'p_alamat_lengkap': cleanAddress,
          'p_foto_url': cleanFoto,
          'p_is_active': isActive,
        },
      );
      if (rpcRes is Map<String, dynamic>) {
        return AdminCourierItemModel.fromMap(rpcRes);
      }
    } catch (_) {
      // Lanjutkan dengan mekanisme tervalidasi standar apabila RPC belum dipasang di database
    }

    // 5. Simpan sesi Admin saat ini sebelum mendaftarkan akun ke Supabase Auth
    // agar sesi Admin tidak tergantikan oleh sesi kurir baru
    final previousRefreshToken = _client.auth.currentSession?.refreshToken;
    String? authUserId;
    try {
      final signUpRes = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'nama_lengkap': cleanName,
          'no_hp': cleanPhone,
          'id_users_role': 2,
          'role': 'courier',
        },
      );
      authUserId = signUpRes.user?.id;

      // Pulihkan sesi Admin jika signUp mengubah sesi aktif
      if (previousRefreshToken != null &&
          _client.auth.currentUser?.email?.toLowerCase() != cleanEmail) {
        try {
          await _client.auth.setSession(previousRefreshToken);
        } catch (_) {}
      }
    } catch (_) {}

    // 6. Insert ke m_employee dengan id_users_role = 2 (Kurir, bukan Admin)
    final payload = <String, dynamic>{
      'employee_code': finalCode,
      'nama_lengkap': cleanName,
      'email': cleanEmail,
      'no_hp': cleanPhone,
      'password': hashedPassword,
      'id_users_role': 2,
      'is_active': isActive,
      if (cleanAddress != null && cleanAddress.isNotEmpty)
        'alamat_lengkap': cleanAddress,
      if (cleanFoto != null && cleanFoto.isNotEmpty) 'foto_url': cleanFoto,
      if (authUserId != null && authUserId.isNotEmpty)
        'auth_user_id': authUserId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    Map<String, dynamic> inserted = {};
    bool success = false;
    int retries = 5;
    int codeSequence = int.tryParse(finalCode.replaceAll(RegExp(r'\D'), '')) ?? 1;

    while (!success && retries > 0) {
      retries--;
      try {
        inserted = await _client
            .from(DatabaseConstants.tableEmployee)
            .insert(payload)
            .select()
            .single();
        success = true;
      } catch (e) {
        if (e is PostgrestException) {
          if (e.message.toLowerCase().contains('unique') ||
              e.message.toLowerCase().contains('duplicate') ||
              e.code == '23505') {
            codeSequence++;
            payload['employee_code'] = codeSequence.toString().padLeft(3, '0');
            continue;
          }
          final colMatch =
              RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
          if (colMatch != null) {
            final missingCol = colMatch.group(1);
            if (missingCol != null && payload.containsKey(missingCol)) {
              payload.remove(missingCol);
              if (missingCol == 'auth_user_id' && authUserId != null) {
                payload['user_id'] = authUserId;
              }
              continue;
            }
          }
        }
        rethrow;
      }
    }

    return AdminCourierItemModel.fromMap(inserted);
  }

  @override
  Future<AdminCourierItemModel> updateCourierProfile({
    required int courierId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? fotoUrl,
    String? newPassword,
    required bool isActive,
  }) async {
    await _requireAdminAuthorization();

    final cleanName = namaLengkap.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = noHp.trim();
    final cleanAddress = alamatLengkap?.trim();
    final cleanFoto = fotoUrl?.trim();

    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final phoneError = Validators.validatePhone(cleanPhone);
    if (phoneError != null) throw Exception(phoneError);

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      final passError = Validators.validatePassword(newPassword.trim());
      if (passError != null) throw Exception(passError);
    }

    // Pastikan email tidak bentrok dengan pegawai lain
    final duplicateEmp = await _client
        .from(DatabaseConstants.tableEmployee)
        .select('id, email')
        .eq(EmployeeTableColumns.email, cleanEmail)
        .neq(EmployeeTableColumns.id, courierId)
        .maybeSingle();
    if (duplicateEmp != null) {
      throw Exception(
        'Email "$cleanEmail" sudah digunakan oleh pegawai lain pada m_employee.',
      );
    }

    final updateData = <String, dynamic>{
      'nama_lengkap': cleanName,
      'email': cleanEmail,
      'no_hp': cleanPhone,
      'alamat_lengkap': cleanAddress,
      'foto_url': cleanFoto,
      'is_active': isActive,
      'id_users_role': 2, // Kunci tetap sebagai courier (role = 2)
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      updateData['password'] = PasswordHasher.hash(newPassword.trim());
    }

    Map<String, dynamic> updated = {};
    bool success = false;
    int retries = 3;

    while (!success && retries > 0) {
      retries--;
      try {
        updated = await _client
            .from(DatabaseConstants.tableEmployee)
            .update(updateData)
            .eq(EmployeeTableColumns.id, courierId)
            .select()
            .single();
        success = true;
      } catch (e) {
        if (e is PostgrestException) {
          final colMatch =
              RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
          if (colMatch != null) {
            final missingCol = colMatch.group(1);
            if (missingCol != null && updateData.containsKey(missingCol)) {
              updateData.remove(missingCol);
              continue;
            }
          }
        }
        rethrow;
      }
    }

    return AdminCourierItemModel.fromMap(updated);
  }

  @override
  Future<void> toggleCourierAccountStatus({
    required int courierId,
    required bool isActive,
  }) async {
    await _requireAdminAuthorization();

    await _client
        .from(DatabaseConstants.tableEmployee)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq(EmployeeTableColumns.id, courierId);
  }

  @override
  Future<void> unassignCourierTask({
    required int assignmentId,
    required int shipmentId,
    String? reason,
  }) async {
    await _requireAdminAuthorization();
    final adminEmpId = await _getActiveAdminEmployeeId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from(DatabaseConstants.tableShipmentAssignments)
        .update({
          'unassigned_at': nowIso,
          if (reason != null && reason.trim().isNotEmpty)
            'catatan': reason.trim(),
        })
        .eq('id', assignmentId);

    // Catat ke t_shipment_tracking sebagai jejak audit penugasan
    try {
      final shipRow = await _client
          .from(DatabaseConstants.tableShipments)
          .select('id, status_id, barcode_value')
          .eq('id', shipmentId)
          .maybeSingle();

      if (shipRow != null) {
        await _client.from(DatabaseConstants.tableShipmentTracking).insert({
          'shipment_id': shipmentId,
          'status_id': shipRow['status_id'],
          'employee_id': ?adminEmpId,
          'barcode_value': shipRow['barcode_value'],
          'lokasi_nama': 'Portal Admin Courier Management',
          'catatan': reason != null && reason.trim().isNotEmpty
              ? 'Penugasan kurir dilepas oleh Admin: ${reason.trim()}'
              : 'Penugasan kurir dilepas oleh Admin untuk penjadwalan ulang.',
          'event_source': 'ADMIN_PORTAL',
          'created_at': nowIso,
        });
      }
    } catch (_) {}
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel(
      'admin_courier_management_${DateTime.now().millisecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableEmployee,
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
          table: DatabaseConstants.tableShipmentLocations,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableShipmentTracking,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    return channel;
  }
}

