import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';
import 'package:satset/features/auth/data/utils/validators.dart';

import '../../domain/entities/admin_customer_item.dart';
import '../models/admin_customer_detail_model.dart';
import '../models/admin_customer_item_model.dart';

abstract class AdminCustomerRemoteDataSource {
  Future<bool> verifyAdminAccess();

  Future<AdminCustomersPaginatedResult> getPaginatedCustomers({
    String? searchQuery,
    String verificationFilter = 'ALL',
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminCustomerDetailModel> getCustomerDetail(int customerId);

  Future<AdminCustomerItemModel> updateCustomerProfile({
    required int customerId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    double? latitude,
    double? longitude,
    required bool emailVerified,
  });

  Future<void> toggleCustomerEmailVerification({
    required int customerId,
    required bool emailVerified,
  });

  Future<List<AdminWilayahOptionModel>> getProvinsiList();
  Future<List<AdminWilayahOptionModel>> getKabkotList(String kodeProvinsi);
  Future<List<AdminWilayahOptionModel>> getKecamatanList(String kodeKabkot);
  Future<List<AdminWilayahOptionModel>> getKelurahanList(String kodeKecamatan);

  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminCustomerRemoteDataSourceImpl
    implements AdminCustomerRemoteDataSource {
  final SupabaseClient _client;

  AdminCustomerRemoteDataSourceImpl({SupabaseClient? client})
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

  /// Resolusi nama wilayah berjenjang (m_provinsi, m_kabkot, m_kecamatan, m_kelurahan) secara batch
  Future<
      ({
        Map<String, String> provinsiByKode,
        Map<String, String> kabkotByKode,
        Map<String, String> kecamatanByKode,
        Map<String, ({String nama, String? kodePos})> kelurahanByKode,
      })> _resolveWilayahMaps({
    required Set<String> provCodes,
    required Set<String> kabCodes,
    required Set<String> kecCodes,
    required Set<String> kelCodes,
  }) async {
    final Map<String, String> provinsiByKode = {};
    final Map<String, String> kabkotByKode = {};
    final Map<String, String> kecamatanByKode = {};
    final Map<String, ({String nama, String? kodePos})> kelurahanByKode = {};

    if (provCodes.isNotEmpty) {
      try {
        final res = await _client
            .from(DatabaseConstants.tableProvinsi)
            .select('kode_provinsi, nama_provinsi')
            .inFilter('kode_provinsi', provCodes.toList());
        for (final r in (res as List)) {
          final k = r['kode_provinsi']?.toString();
          final n = r['nama_provinsi']?.toString();
          if (k != null && n != null) provinsiByKode[k] = n;
        }
      } catch (_) {}
    }

    if (kabCodes.isNotEmpty) {
      try {
        final res = await _client
            .from(DatabaseConstants.tableKabkot)
            .select('kode_kabkot, nama_kabkot, jenis')
            .inFilter('kode_kabkot', kabCodes.toList());
        for (final r in (res as List)) {
          final k = r['kode_kabkot']?.toString();
          final jenis = r['jenis']?.toString() ?? '';
          final nama = r['nama_kabkot']?.toString() ?? '';
          if (k != null && nama.isNotEmpty) {
            kabkotByKode[k] = jenis.isNotEmpty &&
                    !nama.toLowerCase().startsWith(jenis.toLowerCase())
                ? '$jenis $nama'
                : nama;
          }
        }
      } catch (_) {}
    }

    if (kecCodes.isNotEmpty) {
      try {
        final res = await _client
            .from(DatabaseConstants.tableKecamatan)
            .select('kode_kecamatan, nama_kecamatan')
            .inFilter('kode_kecamatan', kecCodes.toList());
        for (final r in (res as List)) {
          final k = r['kode_kecamatan']?.toString();
          final n = r['nama_kecamatan']?.toString();
          if (k != null && n != null) kecamatanByKode[k] = n;
        }
      } catch (_) {}
    }

    if (kelCodes.isNotEmpty) {
      try {
        final res = await _client
            .from(DatabaseConstants.tableKelurahan)
            .select('kode_kelurahan, nama_kelurahan, kodepos')
            .inFilter('kode_kelurahan', kelCodes.toList());
        for (final r in (res as List)) {
          final k = r['kode_kelurahan']?.toString();
          final n = r['nama_kelurahan']?.toString();
          final kp = r['kodepos']?.toString();
          if (k != null && n != null) {
            kelurahanByKode[k] = (nama: n, kodePos: kp);
          }
        }
      } catch (_) {}
    }

    return (
      provinsiByKode: provinsiByKode,
      kabkotByKode: kabkotByKode,
      kecamatanByKode: kecamatanByKode,
      kelurahanByKode: kelurahanByKode,
    );
  }

  @override
  Future<AdminCustomersPaginatedResult> getPaginatedCustomers({
    String? searchQuery,
    String verificationFilter = 'ALL',
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Ambil seluruh customer dari m_users (id_users_role = 3 atau seluruh profil customer pada m_users)
    List<Map<String, dynamic>> rawUsers = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableUsers)
          .select('*')
          .order(UserTableColumns.createdAt, ascending: false);
      rawUsers = List<Map<String, dynamic>>.from(res).where((row) {
        final roleId = int.tryParse(row['id_users_role']?.toString() ?? '3') ?? 3;
        return roleId == 3;
      }).toList();
    } catch (_) {
      final res = await _client
          .from(DatabaseConstants.tableUsers)
          .select('*')
          .order(UserTableColumns.createdAt, ascending: false);
      rawUsers = List<Map<String, dynamic>>.from(res);
    }

    if (rawUsers.isEmpty) {
      return AdminCustomersPaginatedResult.empty;
    }

    // 2. Kumpulkan kode wilayah dari m_users untuk resolusi nama wilayah
    final Set<String> provCodes = {};
    final Set<String> kabCodes = {};
    final Set<String> kecCodes = {};
    final Set<String> kelCodes = {};
    final List<int> customerIds = [];

    for (final u in rawUsers) {
      final cId = int.tryParse(u['id']?.toString() ?? '');
      if (cId != null) customerIds.add(cId);

      final p = u['id_provinsi']?.toString();
      final kb = u['id_kabkot']?.toString();
      final kc = u['id_kecamatan']?.toString();
      final kl = u['id_kelurahan']?.toString();
      if (p != null && p.isNotEmpty) provCodes.add(p);
      if (kb != null && kb.isNotEmpty) kabCodes.add(kb);
      if (kc != null && kc.isNotEmpty) kecCodes.add(kc);
      if (kl != null && kl.isNotEmpty) kelCodes.add(kl);
    }

    final wilayahMaps = await _resolveWilayahMaps(
      provCodes: provCodes,
      kabCodes: kabCodes,
      kecCodes: kecCodes,
      kelCodes: kelCodes,
    );

    // 3. Hitung agregasi pengiriman & pembayaran tiap customer dari t_shipments
    final Map<int, int> totalShipmentsByCustomer = {};
    final Map<int, int> deliveredShipmentsByCustomer = {};
    final Map<int, int> ongoingShipmentsByCustomer = {};
    final Map<int, int> failedShipmentsByCustomer = {};
    final Map<int, num> totalPaymentAmountByCustomer = {};

    if (customerIds.isNotEmpty) {
      try {
        final shipRes = await _client
            .from(DatabaseConstants.tableShipments)
            .select('''
              id,
              customer_id,
              total_biaya,
              ${DatabaseConstants.tableShipmentStatuses}(kode)
            ''')
            .inFilter('customer_id', customerIds);

        for (final s in (shipRes as List)) {
          final cId = int.tryParse(s['customer_id']?.toString() ?? '');
          if (cId == null) continue;

          totalShipmentsByCustomer[cId] =
              (totalShipmentsByCustomer[cId] ?? 0) + 1;

          final biaya = num.tryParse(s['total_biaya']?.toString() ?? '0') ?? 0;
          totalPaymentAmountByCustomer[cId] =
              (totalPaymentAmountByCustomer[cId] ?? 0) + biaya;

          final statusObj = s['m_shipment_statuses'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(s['m_shipment_statuses'] as Map)
              : <String, dynamic>{};
          final statusCode = (statusObj['kode'] ?? '').toString().toUpperCase();

          if (statusCode == 'DELIVERED') {
            deliveredShipmentsByCustomer[cId] =
                (deliveredShipmentsByCustomer[cId] ?? 0) + 1;
          } else if (statusCode == 'FAILED_DELIVERY' ||
              statusCode == 'RETURNED' ||
              statusCode == 'CANCELLED') {
            failedShipmentsByCustomer[cId] =
                (failedShipmentsByCustomer[cId] ?? 0) + 1;
          } else {
            ongoingShipmentsByCustomer[cId] =
                (ongoingShipmentsByCustomer[cId] ?? 0) + 1;
          }
        }
      } catch (_) {}
    }

    // 4. Konversi menjadi list AdminCustomerItemModel
    final allCustomers = rawUsers.map((row) {
      final cId = int.tryParse(row['id']?.toString() ?? '0') ?? 0;
      final pCode = row['id_provinsi']?.toString();
      final kbCode = row['id_kabkot']?.toString();
      final kcCode = row['id_kecamatan']?.toString();
      final klCode = row['id_kelurahan']?.toString();
      final kelInfo =
          klCode != null ? wilayahMaps.kelurahanByKode[klCode] : null;

      return AdminCustomerItemModel.fromMap(
        row,
        namaProvinsi: pCode != null ? wilayahMaps.provinsiByKode[pCode] : null,
        namaKabkot: kbCode != null ? wilayahMaps.kabkotByKode[kbCode] : null,
        namaKecamatan:
            kcCode != null ? wilayahMaps.kecamatanByKode[kcCode] : null,
        namaKelurahan: kelInfo?.nama,
        kodePos: kelInfo?.kodePos,
        totalShipmentsCount: totalShipmentsByCustomer[cId] ?? 0,
        deliveredShipmentsCount: deliveredShipmentsByCustomer[cId] ?? 0,
        ongoingShipmentsCount: ongoingShipmentsByCustomer[cId] ?? 0,
        failedShipmentsCount: failedShipmentsByCustomer[cId] ?? 0,
        totalTransactionAmount: totalPaymentAmountByCustomer[cId] ?? 0,
      );
    }).toList();

    // 5. Hitung Ringkasan Statistik Aktual seluruh customer (m_users)
    int verifiedCount = 0;
    int unverifiedCount = 0;
    int newThisMonthCount = 0;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final c in allCustomers) {
      if (c.emailVerified) {
        verifiedCount++;
      } else {
        unverifiedCount++;
      }
      if (c.createdAt.isAfter(thirtyDaysAgo)) {
        newThisMonthCount++;
      }
    }

    final summaryStats = AdminCustomerSummaryStats(
      totalCustomers: allCustomers.length,
      verifiedCustomers: verifiedCount,
      unverifiedCustomers: unverifiedCount,
      newCustomersThisMonth: newThisMonthCount,
    );

    // 6. Terapkan pencarian dan filter
    final q = (searchQuery ?? '').trim().toLowerCase();
    final filtered = allCustomers.where((c) {
      // Filter status verifikasi
      if (verificationFilter == 'VERIFIED' && !c.emailVerified) return false;
      if (verificationFilter == 'UNVERIFIED' && c.emailVerified) return false;
      if (verificationFilter == 'NEW_30_DAYS' &&
          !c.createdAt.isAfter(thirtyDaysAgo)) {
        return false;
      }

      // Filter rentang tanggal registrasi
      if (startDate != null) {
        final startDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        if (c.createdAt.isBefore(startDay)) return false;
      }
      if (endDate != null) {
        final endDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (c.createdAt.isAfter(endDay)) return false;
      }

      // Pencarian berdasarkan nama lengkap, email, atau nomor telepon
      if (q.isNotEmpty) {
        final matchName = c.namaLengkap.toLowerCase().contains(q);
        final matchEmail = c.email.toLowerCase().contains(q);
        final matchPhone = c.noHp.toLowerCase().contains(q);
        final matchAddress =
            (c.alamatLengkap ?? '').toLowerCase().contains(q) ||
                c.formattedWilayahSummary.toLowerCase().contains(q);
        if (!matchName && !matchEmail && !matchPhone && !matchAddress) {
          return false;
        }
      }

      return true;
    }).toList();

    // 7. Pengurutan berdasarkan nama atau tanggal pendaftaran atau total pengiriman
    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'nama_lengkap':
          cmp = a.namaLengkap
              .toLowerCase()
              .compareTo(b.namaLengkap.toLowerCase());
          break;
        case 'total_shipments':
          cmp = a.totalShipmentsCount.compareTo(b.totalShipmentsCount);
          break;
        case 'total_amount':
          cmp = a.totalTransactionAmount.compareTo(b.totalTransactionAmount);
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
        ? <AdminCustomerItemModel>[]
        : filtered.skip(startIndex).take(pageSize).toList();

    return AdminCustomersPaginatedResult(
      items: pagedItems,
      totalCount: totalFiltered,
      currentPage: safePage,
      pageSize: pageSize,
      summaryStats: summaryStats,
    );
  }

  @override
  Future<AdminCustomerDetailModel> getCustomerDetail(int customerId) async {
    await _requireAdminAuthorization();

    // 1. Ambil profil customer dari m_users
    final userRow = await _client
        .from(DatabaseConstants.tableUsers)
        .select('*')
        .eq(UserTableColumns.id, customerId)
        .maybeSingle();

    if (userRow == null) {
      throw Exception(
        'Data customer (ID: $customerId) tidak ditemukan pada tabel m_users.',
      );
    }

    // 2. Ambil daftar alamat tambahan dari m_address + m_label apabila tersedia
    List<Map<String, dynamic>> rawAddresses = [];
    try {
      final addrRes = await _client
          .from(DatabaseConstants.tableAddress)
          .select('*, ${DatabaseConstants.tableLabel}(id, nm_label)')
          .eq(AddressTableColumns.idUsers, customerId)
          .order(AddressTableColumns.createdAt, ascending: false);
      rawAddresses = List<Map<String, dynamic>>.from(addrRes);
    } catch (_) {
      try {
        final fallbackAddr = await _client
            .from(DatabaseConstants.tableAddress)
            .select('*')
            .eq(AddressTableColumns.idUsers, customerId)
            .order(AddressTableColumns.createdAt, ascending: false);
        rawAddresses = List<Map<String, dynamic>>.from(fallbackAddr);
      } catch (_) {}
    }

    // Kumpulkan kode wilayah dari profil utama dan daftar m_address
    final Set<String> provCodes = {};
    final Set<String> kabCodes = {};
    final Set<String> kecCodes = {};
    final Set<String> kelCodes = {};

    void collectWilayahCodes(Map<String, dynamic> map) {
      final p = map['id_provinsi']?.toString();
      final kb = map['id_kabkot']?.toString();
      final kc = map['id_kecamatan']?.toString();
      final kl = map['id_kelurahan']?.toString();
      if (p != null && p.isNotEmpty) provCodes.add(p);
      if (kb != null && kb.isNotEmpty) kabCodes.add(kb);
      if (kc != null && kc.isNotEmpty) kecCodes.add(kc);
      if (kl != null && kl.isNotEmpty) kelCodes.add(kl);
    }

    collectWilayahCodes(userRow);
    for (final a in rawAddresses) {
      collectWilayahCodes(a);
    }

    final wilayahMaps = await _resolveWilayahMaps(
      provCodes: provCodes,
      kabCodes: kabCodes,
      kecCodes: kecCodes,
      kelCodes: kelCodes,
    );

    final additionalAddresses = rawAddresses.map((addrMap) {
      final pCode = addrMap['id_provinsi']?.toString();
      final kbCode = addrMap['id_kabkot']?.toString();
      final kcCode = addrMap['id_kecamatan']?.toString();
      final klCode = addrMap['id_kelurahan']?.toString();
      return AdminCustomerAddressRecordModel.fromMap(
        addrMap,
        namaProvinsi: pCode != null ? wilayahMaps.provinsiByKode[pCode] : null,
        namaKabkot: kbCode != null ? wilayahMaps.kabkotByKode[kbCode] : null,
        namaKecamatan:
            kcCode != null ? wilayahMaps.kecamatanByKode[kcCode] : null,
        namaKelurahan:
            klCode != null ? wilayahMaps.kelurahanByKode[klCode]?.nama : null,
      );
    }).toList();

    // 3. Ambil riwayat pengiriman customer dari t_shipments + m_shipment_statuses + m_service_types + t_shipment_payments
    List<AdminCustomerShipmentRecordModel> shipments = [];
    int deliveredCount = 0;
    int ongoingCount = 0;
    int failedCount = 0;
    num totalTransactionAmount = 0;

    try {
      final shipRes = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status),
            ${DatabaseConstants.tableServiceTypes}(id, kode, nama_layanan),
            ${DatabaseConstants.tableShipmentPayments}(id, metode_pembayaran, status_pembayaran, jumlah_bayar)
          ''')
          .eq(ShipmentTableColumns.customerId, customerId)
          .order(ShipmentTableColumns.createdAt, ascending: false);

      final rawShipList = List<Map<String, dynamic>>.from(shipRes);
      final shipmentIds = rawShipList
          .map((e) => int.tryParse(e['id']?.toString() ?? ''))
          .whereType<int>()
          .toList();

      // Ambil kronologi perjalanan paket dari t_shipment_tracking untuk seluruh pengiriman customer ini
      final Map<int, List<AdminCustomerShipmentTrackingStepModel>>
          trackingByShipmentId = {};
      if (shipmentIds.isNotEmpty) {
        try {
          final trackRes = await _client
              .from(DatabaseConstants.tableShipmentTracking)
              .select('''
                *,
                ${DatabaseConstants.tableShipmentStatuses}(kode, nama_status)
              ''')
              .inFilter('shipment_id', shipmentIds)
              .order('created_at', ascending: false);

          for (final tr in (trackRes as List)) {
            final sId = int.tryParse(tr['shipment_id']?.toString() ?? '');
            if (sId != null) {
              trackingByShipmentId
                  .putIfAbsent(
                    sId,
                    () => <AdminCustomerShipmentTrackingStepModel>[],
                  )
                  .add(
                    AdminCustomerShipmentTrackingStepModel.fromMap(
                      Map<String, dynamic>.from(tr as Map),
                    ),
                  );
            }
          }
        } catch (_) {}
      }

      for (final sMap in rawShipList) {
        final sId = int.tryParse(sMap['id']?.toString() ?? '0') ?? 0;
        final model = AdminCustomerShipmentRecordModel.fromMap(
          sMap,
          trackingSteps: trackingByShipmentId[sId] ?? const [],
        );
        shipments.add(model);

        totalTransactionAmount += model.totalBiaya;
        final code = model.statusKode.toUpperCase();
        if (code == 'DELIVERED') {
          deliveredCount++;
        } else if (code == 'FAILED_DELIVERY' ||
            code == 'RETURNED' ||
            code == 'CANCELLED') {
          failedCount++;
        } else {
          ongoingCount++;
        }
      }
    } catch (_) {}

    final uProv = userRow['id_provinsi']?.toString();
    final uKab = userRow['id_kabkot']?.toString();
    final uKec = userRow['id_kecamatan']?.toString();
    final uKel = userRow['id_kelurahan']?.toString();
    final kelInfo = uKel != null ? wilayahMaps.kelurahanByKode[uKel] : null;

    final customerModel = AdminCustomerItemModel.fromMap(
      Map<String, dynamic>.from(userRow),
      namaProvinsi: uProv != null ? wilayahMaps.provinsiByKode[uProv] : null,
      namaKabkot: uKab != null ? wilayahMaps.kabkotByKode[uKab] : null,
      namaKecamatan: uKec != null ? wilayahMaps.kecamatanByKode[uKec] : null,
      namaKelurahan: kelInfo?.nama,
      kodePos: kelInfo?.kodePos,
      totalShipmentsCount: shipments.length,
      deliveredShipmentsCount: deliveredCount,
      ongoingShipmentsCount: ongoingCount,
      failedShipmentsCount: failedCount,
      totalTransactionAmount: totalTransactionAmount,
    );

    return AdminCustomerDetailModel.create(
      customer: customerModel,
      additionalAddresses: additionalAddresses,
      shipments: shipments,
    );
  }

  @override
  Future<AdminCustomerItemModel> updateCustomerProfile({
    required int customerId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    double? latitude,
    double? longitude,
    required bool emailVerified,
  }) async {
    await _requireAdminAuthorization();

    final cleanName = namaLengkap.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = noHp.trim();
    final cleanAddress = alamatLengkap?.trim();

    final nameError = Validators.validateName(cleanName);
    if (nameError != null) throw Exception(nameError);

    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) throw Exception(emailError);

    final phoneError = Validators.validatePhone(cleanPhone);
    if (phoneError != null) throw Exception(phoneError);

    // Pastikan email tidak bentrok dengan customer lain di m_users
    final duplicateUser = await _client
        .from(DatabaseConstants.tableUsers)
        .select('id, email')
        .eq(UserTableColumns.email, cleanEmail)
        .neq(UserTableColumns.id, customerId)
        .maybeSingle();
    if (duplicateUser != null) {
      throw Exception(
        'Email "$cleanEmail" sudah digunakan oleh akun customer lain pada m_users.',
      );
    }

    // Penting: Jangan pernah mengubah kolom password customer secara langsung dari portal Admin
    final updateData = <String, dynamic>{
      UserTableColumns.namaLengkap: cleanName,
      UserTableColumns.email: cleanEmail,
      UserTableColumns.noHp: cleanPhone,
      UserTableColumns.alamatLengkap: cleanAddress,
      UserTableColumns.idProvinsi:
          (idProvinsi != null && idProvinsi.isNotEmpty) ? idProvinsi : null,
      UserTableColumns.idKabkot:
          (idKabkot != null && idKabkot.isNotEmpty) ? idKabkot : null,
      UserTableColumns.idKecamatan:
          (idKecamatan != null && idKecamatan.isNotEmpty) ? idKecamatan : null,
      UserTableColumns.idKelurahan:
          (idKelurahan != null && idKelurahan.isNotEmpty) ? idKelurahan : null,
      UserTableColumns.latitude: latitude,
      UserTableColumns.longitude: longitude,
      UserTableColumns.emailVerified: emailVerified,
      if (emailVerified)
        UserTableColumns.emailVerifiedAt:
            DateTime.now().toUtc().toIso8601String(),
      UserTableColumns.idUsersRole: 3, // Tetap dikunci sebagai customer (role = 3)
      UserTableColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    Map<String, dynamic> updated = {};
    bool success = false;
    int retries = 3;

    while (!success && retries > 0) {
      retries--;
      try {
        updated = await _client
            .from(DatabaseConstants.tableUsers)
            .update(updateData)
            .eq(UserTableColumns.id, customerId)
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
          if (e.message.contains('fk_users_kelurahan') ||
              e.message.contains('id_kelurahan')) {
            updateData.remove(UserTableColumns.idKelurahan);
            continue;
          }
        }
        rethrow;
      }
    }

    return AdminCustomerItemModel.fromMap(updated);
  }

  @override
  Future<void> toggleCustomerEmailVerification({
    required int customerId,
    required bool emailVerified,
  }) async {
    await _requireAdminAuthorization();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from(DatabaseConstants.tableUsers)
        .update({
          UserTableColumns.emailVerified: emailVerified,
          UserTableColumns.emailVerifiedAt: emailVerified ? nowIso : null,
          UserTableColumns.updatedAt: nowIso,
        })
        .eq(UserTableColumns.id, customerId);
  }

  @override
  Future<List<AdminWilayahOptionModel>> getProvinsiList() async {
    try {
      final res = await _client
          .from(DatabaseConstants.tableProvinsi)
          .select('kode_provinsi, nama_provinsi')
          .order('nama_provinsi', ascending: true);
      return (res as List)
          .map(
            (e) => AdminWilayahOptionModel.fromProvinsiMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AdminWilayahOptionModel>> getKabkotList(
    String kodeProvinsi,
  ) async {
    if (kodeProvinsi.trim().isEmpty) return [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableKabkot)
          .select('kode_kabkot, kode_provinsi, nama_kabkot, jenis')
          .eq(KabkotTableColumns.kodeProvinsi, kodeProvinsi.trim())
          .order('nama_kabkot', ascending: true);
      return (res as List)
          .map(
            (e) => AdminWilayahOptionModel.fromKabkotMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AdminWilayahOptionModel>> getKecamatanList(
    String kodeKabkot,
  ) async {
    if (kodeKabkot.trim().isEmpty) return [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableKecamatan)
          .select('kode_kecamatan, kode_kabkot, nama_kecamatan')
          .eq(KecamatanTableColumns.kodeKabkot, kodeKabkot.trim())
          .order('nama_kecamatan', ascending: true);
      return (res as List)
          .map(
            (e) => AdminWilayahOptionModel.fromKecamatanMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AdminWilayahOptionModel>> getKelurahanList(
    String kodeKecamatan,
  ) async {
    if (kodeKecamatan.trim().isEmpty) return [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableKelurahan)
          .select('kode_kelurahan, kode_kecamatan, nama_kelurahan, kodepos')
          .eq(KelurahanTableColumns.kodeKecamatan, kodeKecamatan.trim())
          .order('nama_kelurahan', ascending: true);
      return (res as List)
          .map(
            (e) => AdminWilayahOptionModel.fromKelurahanMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel(
      'admin_customer_management_${DateTime.now().millisecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableUsers,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableAddress,
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
}

