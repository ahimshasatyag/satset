import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/data/datasources/admin_auth_local_datasource.dart';

import '../../domain/entities/admin_service_type_detail.dart';
import '../../domain/entities/admin_service_type_item.dart';
import '../models/admin_service_type_detail_model.dart';
import '../models/admin_service_type_item_model.dart';

abstract class AdminServiceTypeRemoteDataSource {
  Future<bool> verifyAdminAccess();

  Future<AdminServiceTypesPaginatedResult> getPaginatedServiceTypes({
    String? searchQuery,
    String statusFilter = 'ALL',
    String sortColumn = 'id',
    bool sortAscending = true,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminServiceTypeDetailModel> getServiceTypeDetail(int serviceId);

  Future<AdminServiceTypeItemModel> createServiceType({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    bool isActive = true,
  });

  Future<AdminServiceTypeItemModel> updateServiceType({
    required int serviceId,
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  });

  Future<void> toggleServiceTypeStatus({
    required int serviceId,
    required bool isActive,
  });

  Future<void> deleteServiceType(int serviceId);

  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  });
}

class AdminServiceTypeRemoteDataSourceImpl
    implements AdminServiceTypeRemoteDataSource {
  final SupabaseClient _client;

  AdminServiceTypeRemoteDataSourceImpl({SupabaseClient? client})
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

  @override
  Future<AdminServiceTypesPaginatedResult> getPaginatedServiceTypes({
    String? searchQuery,
    String statusFilter = 'ALL',
    String sortColumn = 'id',
    bool sortAscending = true,
    int page = 1,
    int pageSize = 10,
  }) async {
    // 1. Ambil seluruh baris m_service_types dari Supabase
    List<Map<String, dynamic>> rawServices = [];
    try {
      final res = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select()
          .order(ServiceTypeTableColumns.id, ascending: true);
      rawServices = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      rawServices = [];
    }

    // 2. Ambil statistik pemakaian aktual dari t_shipments berdasarkan service_type_id
    final totalShipMap = <int, int>{};
    final activeShipMap = <int, int>{};
    final deliveredShipMap = <int, int>{};
    final revenueMap = <int, num>{};

    try {
      final shipRes = await _client
          .from(DatabaseConstants.tableShipments)
          .select('id, service_type_id, status_id, total_biaya');

      for (final s in (shipRes as List)) {
        final sId = int.tryParse(s['service_type_id']?.toString() ?? '');
        if (sId == null) continue;

        final statusId = int.tryParse(s['status_id']?.toString() ?? '1') ?? 1;
        final totalBiaya =
            num.tryParse(s['total_biaya']?.toString() ?? '0') ?? 0;

        totalShipMap[sId] = (totalShipMap[sId] ?? 0) + 1;
        revenueMap[sId] = (revenueMap[sId] ?? 0) + totalBiaya;

        if (statusId == 8) {
          deliveredShipMap[sId] = (deliveredShipMap[sId] ?? 0) + 1;
        } else if (statusId >= 1 && statusId <= 7) {
          activeShipMap[sId] = (activeShipMap[sId] ?? 0) + 1;
        }
      }
    } catch (_) {}

    // 3. Petakan ke model
    final List<AdminServiceTypeItemModel> allItems = [];
    int activeServicesCount = 0;
    int inactiveServicesCount = 0;
    int usedServicesCount = 0;
    int totalShipmentsUsing = 0;
    num totalRevenueAll = 0;

    for (final row in rawServices) {
      final id = int.tryParse(row['id']?.toString() ?? '0') ?? 0;
      final tCount = totalShipMap[id] ?? 0;
      final aCount = activeShipMap[id] ?? 0;
      final dCount = deliveredShipMap[id] ?? 0;
      final rev = revenueMap[id] ?? 0;

      final model = AdminServiceTypeItemModel.fromMap(
        row,
        totalShipmentsCount: tCount,
        activeShipmentsCount: aCount,
        deliveredShipmentsCount: dCount,
        totalRevenueAmount: rev,
      );

      allItems.add(model);

      if (model.isActive) {
        activeServicesCount++;
      } else {
        inactiveServicesCount++;
      }
      if (tCount > 0) {
        usedServicesCount++;
        totalShipmentsUsing += tCount;
        totalRevenueAll += rev;
      }
    }

    final summaryStats = AdminServiceTypeSummaryStats(
      totalServices: allItems.length,
      activeServices: activeServicesCount,
      inactiveServices: inactiveServicesCount,
      usedServicesCount: usedServicesCount,
      totalShipmentsUsingServices: totalShipmentsUsing,
      totalRevenueFromServices: totalRevenueAll,
    );

    // 4. Filter berdasarkan status dan pencarian
    final filtered = allItems.where((item) {
      switch (statusFilter.toUpperCase()) {
        case 'ACTIVE':
          if (!item.isActive) return false;
          break;
        case 'INACTIVE':
          if (item.isActive) return false;
          break;
        case 'USED':
          if (!item.isUsedInShipments) return false;
          break;
        case 'UNUSED':
          if (item.isUsedInShipments) return false;
          break;
        case 'ALL':
        default:
          break;
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchId = item.id.toString().contains(q);
        final matchKode = item.kode.toLowerCase().contains(q);
        final matchNama = item.namaLayanan.toLowerCase().contains(q);
        final matchDesc = (item.deskripsi ?? '').toLowerCase().contains(q);

        if (!matchId && !matchKode && !matchNama && !matchDesc) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Pengurutan Kolom (Sorting)
    filtered.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case 'kode':
          cmp = a.kode.toLowerCase().compareTo(b.kode.toLowerCase());
          break;
        case 'nama_layanan':
          cmp = a.namaLayanan
              .toLowerCase()
              .compareTo(b.namaLayanan.toLowerCase());
          break;
        case 'harga_dasar':
          cmp = a.baseTariffPerKg.compareTo(b.baseTariffPerKg);
          break;
        case 'shipment_count':
          cmp = a.totalShipmentsCount.compareTo(b.totalShipmentsCount);
          break;
        case 'created_at':
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dA.compareTo(dB);
          break;
        case 'id':
        default:
          cmp = a.id.compareTo(b.id);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });

    // 6. Paginasi
    final totalFiltered = filtered.length;
    final safePage = page < 1 ? 1 : page;
    final startIndex = (safePage - 1) * pageSize;
    final pagedItems = startIndex >= totalFiltered
        ? <AdminServiceTypeItemModel>[]
        : filtered.skip(startIndex).take(pageSize).toList();

    return AdminServiceTypesPaginatedResult(
      items: pagedItems,
      totalCount: totalFiltered,
      currentPage: safePage,
      pageSize: pageSize,
      summaryStats: summaryStats,
    );
  }

  @override
  Future<AdminServiceTypeDetailModel> getServiceTypeDetail(
    int serviceId,
  ) async {
    final row = await _client
        .from(DatabaseConstants.tableServiceTypes)
        .select()
        .eq(ServiceTypeTableColumns.id, serviceId)
        .single();
    final rowMap = Map<String, dynamic>.from(row as Map);

    // Ambil seluruh pengiriman yang menggunakan layanan ini
    int totalCount = 0;
    int activeCount = 0;
    int deliveredCount = 0;
    num revenueSum = 0;
    final List<AdminServiceShipmentUsageRecord> recentShipments = [];

    try {
      final shipRes = await _client
          .from(DatabaseConstants.tableShipments)
          .select('''
            id,
            nomor_resi,
            pengirim_nama,
            pengirim_kota,
            penerima_nama,
            penerima_kota,
            total_berat_gram,
            biaya_pengiriman,
            total_biaya,
            status_id,
            created_at,
            ${DatabaseConstants.tableShipmentStatuses}(id, kode, nama_status)
          ''')
          .eq(ShipmentTableColumns.serviceTypeId, serviceId)
          .order(ShipmentTableColumns.createdAt, ascending: false);

      final shipList = shipRes as List;
      totalCount = shipList.length;

      for (int i = 0; i < shipList.length; i++) {
        final sMap = Map<String, dynamic>.from(shipList[i] as Map);
        final statusId =
            int.tryParse(sMap['status_id']?.toString() ?? '1') ?? 1;
        final totalBiaya =
            num.tryParse(sMap['total_biaya']?.toString() ?? '0') ?? 0;

        revenueSum += totalBiaya;
        if (statusId == 8) {
          deliveredCount++;
        } else if (statusId >= 1 && statusId <= 7) {
          activeCount++;
        }

        if (i < 15) {
          recentShipments.add(
            AdminServiceShipmentUsageRecordModel.fromMap(sMap),
          );
        }
      }
    } catch (_) {}

    final serviceItem = AdminServiceTypeItemModel.fromMap(
      rowMap,
      totalShipmentsCount: totalCount,
      activeShipmentsCount: activeCount,
      deliveredShipmentsCount: deliveredCount,
      totalRevenueAmount: revenueSum,
    );

    return AdminServiceTypeDetailModel.fromData(
      serviceType: serviceItem,
      recentShipments: recentShipments,
    );
  }

  @override
  Future<AdminServiceTypeItemModel> createServiceType({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    bool isActive = true,
  }) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang dapat menambahkan jenis layanan.',
      );
    }

    final cleanKode = kode.trim().toUpperCase();
    final cleanNama = namaLayanan.trim();

    if (cleanKode.isEmpty || cleanNama.isEmpty) {
      throw Exception('Kode layanan dan nama layanan wajib diisi.');
    }
    if (estimasiHariMin < 0 || estimasiHariMax < estimasiHariMin) {
      throw Exception(
        'Estimasi hari maksimum tidak boleh lebih kecil dari estimasi hari minimum.',
      );
    }

    // Periksa duplikasi kode layanan pada m_service_types
    final existingKode = await _client
        .from(DatabaseConstants.tableServiceTypes)
        .select('id, kode')
        .ilike(ServiceTypeTableColumns.kode, cleanKode)
        .maybeSingle();

    if (existingKode != null) {
      throw Exception(
        'Kode layanan "$cleanKode" sudah terdaftar pada m_service_types. Gunakan kode layanan yang unik.',
      );
    }

    final basePayload = <String, dynamic>{
      ServiceTypeTableColumns.kode: cleanKode,
      ServiceTypeTableColumns.namaLayanan: cleanNama,
      ServiceTypeTableColumns.estimasiHariMin: estimasiHariMin,
      ServiceTypeTableColumns.estimasiHariMax: estimasiHariMax,
      ServiceTypeTableColumns.deskripsi:
          (deskripsi != null && deskripsi.trim().isNotEmpty)
              ? deskripsi.trim()
              : null,
      ServiceTypeTableColumns.isActive: isActive,
    };

    Map<String, dynamic> insertedRow;
    if (baseTariffPerKg != null && baseTariffPerKg > 0) {
      try {
        final payloadWithTariff = {
          ...basePayload,
          'harga_dasar': baseTariffPerKg,
        };
        final res = await _client
            .from(DatabaseConstants.tableServiceTypes)
            .insert(payloadWithTariff)
            .select()
            .single();
        insertedRow = Map<String, dynamic>.from(res as Map);
      } catch (_) {
        // Fallback jika kolom opsional harga_dasar tidak ada di tabel m_service_types
        final res = await _client
            .from(DatabaseConstants.tableServiceTypes)
            .insert(basePayload)
            .select()
            .single();
        insertedRow = Map<String, dynamic>.from(res as Map);
      }
    } else {
      final res = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .insert(basePayload)
          .select()
          .single();
      insertedRow = Map<String, dynamic>.from(res as Map);
    }

    return AdminServiceTypeItemModel.fromMap(insertedRow);
  }

  @override
  Future<AdminServiceTypeItemModel> updateServiceType({
    required int serviceId,
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  }) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang dapat mengubah jenis layanan.',
      );
    }

    final cleanKode = kode.trim().toUpperCase();
    final cleanNama = namaLayanan.trim();

    if (cleanKode.isEmpty || cleanNama.isEmpty) {
      throw Exception('Kode layanan dan nama layanan wajib diisi.');
    }
    if (estimasiHariMin < 0 || estimasiHariMax < estimasiHariMin) {
      throw Exception(
        'Estimasi hari maksimum tidak boleh lebih kecil dari estimasi hari minimum.',
      );
    }

    // Periksa duplikasi kode layanan terhadap layanan lain
    final duplicate = await _client
        .from(DatabaseConstants.tableServiceTypes)
        .select('id, kode')
        .ilike(ServiceTypeTableColumns.kode, cleanKode)
        .neq(ServiceTypeTableColumns.id, serviceId)
        .maybeSingle();

    if (duplicate != null) {
      throw Exception(
        'Kode layanan "$cleanKode" sudah digunakan oleh jenis layanan lain pada m_service_types.',
      );
    }

    final basePayload = <String, dynamic>{
      ServiceTypeTableColumns.kode: cleanKode,
      ServiceTypeTableColumns.namaLayanan: cleanNama,
      ServiceTypeTableColumns.estimasiHariMin: estimasiHariMin,
      ServiceTypeTableColumns.estimasiHariMax: estimasiHariMax,
      ServiceTypeTableColumns.deskripsi:
          (deskripsi != null && deskripsi.trim().isNotEmpty)
              ? deskripsi.trim()
              : null,
      ServiceTypeTableColumns.isActive: isActive,
    };

    Map<String, dynamic> updatedRow;
    if (baseTariffPerKg != null && baseTariffPerKg > 0) {
      try {
        final payloadWithTariff = {
          ...basePayload,
          'harga_dasar': baseTariffPerKg,
        };
        final res = await _client
            .from(DatabaseConstants.tableServiceTypes)
            .update(payloadWithTariff)
            .eq(ServiceTypeTableColumns.id, serviceId)
            .select()
            .single();
        updatedRow = Map<String, dynamic>.from(res as Map);
      } catch (_) {
        final res = await _client
            .from(DatabaseConstants.tableServiceTypes)
            .update(basePayload)
            .eq(ServiceTypeTableColumns.id, serviceId)
            .select()
            .single();
        updatedRow = Map<String, dynamic>.from(res as Map);
      }
    } else {
      final res = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .update(basePayload)
          .eq(ServiceTypeTableColumns.id, serviceId)
          .select()
          .single();
      updatedRow = Map<String, dynamic>.from(res as Map);
    }

    return AdminServiceTypeItemModel.fromMap(updatedRow);
  }

  @override
  Future<void> toggleServiceTypeStatus({
    required int serviceId,
    required bool isActive,
  }) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang dapat mengubah status jenis layanan.',
      );
    }

    await _client
        .from(DatabaseConstants.tableServiceTypes)
        .update({
          ServiceTypeTableColumns.isActive: isActive,
        })
        .eq(ServiceTypeTableColumns.id, serviceId);
  }

  @override
  Future<void> deleteServiceType(int serviceId) async {
    final hasAccess = await verifyAdminAccess();
    if (!hasAccess) {
      throw Exception(
        'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang dapat menghapus jenis layanan.',
      );
    }

    // Periksa apakah layanan ini sudah pernah digunakan pada t_shipments
    final usedRows = await _client
        .from(DatabaseConstants.tableShipments)
        .select('id')
        .eq(ShipmentTableColumns.serviceTypeId, serviceId)
        .limit(1);

    if ((usedRows as List).isNotEmpty) {
      throw Exception(
        'Tidak dapat menghapus jenis layanan ini karena sudah digunakan pada transaksi pengiriman (t_shipments). Gunakan fitur Nonaktifkan Layanan agar histori pengiriman tetap terjaga dan layanan tidak muncul pada pesanan baru.',
      );
    }

    await _client
        .from(DatabaseConstants.tableServiceTypes)
        .delete()
        .eq(ServiceTypeTableColumns.id, serviceId);
  }

  @override
  RealtimeChannel subscribeToRealtimeUpdates({
    required void Function() onDataChanged,
  }) {
    final channel = _client.channel(
      'admin_service_types_channel_${DateTime.now().millisecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DatabaseConstants.tableServiceTypes,
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

