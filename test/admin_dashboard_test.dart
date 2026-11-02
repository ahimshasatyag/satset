import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/admin/dashboard/data/models/admin_activity_model.dart';
import 'package:satset/features/admin/dashboard/data/models/admin_courier_summary_model.dart';
import 'package:satset/features/admin/dashboard/data/models/admin_dashboard_stats_model.dart';
import 'package:satset/features/admin/dashboard/data/models/admin_shipment_detail_model.dart';
import 'package:satset/features/admin/dashboard/data/models/admin_shipment_table_model.dart';
import 'package:satset/features/admin/dashboard/domain/entities/admin_activity.dart';
import 'package:satset/features/admin/dashboard/domain/entities/admin_courier_summary.dart';
import 'package:satset/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';
import 'package:satset/features/admin/dashboard/domain/entities/admin_shipment_detail.dart';
import 'package:satset/features/admin/dashboard/domain/entities/admin_shipment_table_item.dart';
import 'package:satset/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:satset/features/admin/dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:satset/features/admin/dashboard/presentation/bloc/admin_dashboard_event.dart';
import 'package:satset/features/admin/dashboard/presentation/bloc/admin_dashboard_state.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/features/admin/dashboard/data/datasources/admin_dashboard_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAdminDashboardRemoteDataSource implements AdminDashboardRemoteDataSource {
  @override
  Future<bool> verifyAdminAccess() async => true;

  @override
  Future<List<AdminCourierSummaryModel>> getCourierSummaries() async => [
        const AdminCourierSummaryModel(
          courierId: 1,
          namaLengkap: 'Budi Santoso',
          employeeCode: 'EXP-1',
          noHp: '08123456789',
          activeAssignmentsCount: 3,
          completedAssignmentsCount: 15,
          hasActiveDuty: true,
        ),
      ];

  @override
  Future<List<AdminActivityModel>> getRecentActivities({int limit = 10}) async => [];

  @override
  Future<AdminDashboardStatsModel> getDashboardStats() async => const AdminDashboardStatsModel(
        totalShipments: 100,
        pendingShipments: 10,
        inProcessShipments: 40,
        deliveredShipments: 45,
        failedShipments: 3,
        cancelledShipments: 2,
        totalCustomers: 50,
        totalEmployees: 12,
        totalAdmins: 2,
        totalCouriers: 10,
        activeCouriersCount: 5,
        couriersWithAssignmentCount: 5,
        statusDistributions: [
          AdminStatusDistribution(statusCode: 'DELIVERED', statusName: 'Berhasil Terkirim', count: 45, percentage: 45.0),
        ],
        dailyTrends: [
          AdminTrendPoint(label: '02/11', total: 10, delivered: 8, failed: 1),
        ],
        weeklyTrends: [],
        monthlyTrends: [],
        paymentSummary: AdminPaymentSummary(
          totalAmount: 1500000,
          paidAmount: 1200000,
          pendingAmount: 200000,
          codAmount: 100000,
          totalCount: 50,
          paidCount: 40,
          pendingCount: 8,
          codCount: 2,
        ),
      );

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
  }) async =>
      AdminShipmentsPaginatedResult(
        items: [
          AdminShipmentTableModel(
            id: 1,
            nomorResi: 'SATSET-TEST-001',
            barcodeValue: 'SATSET-TEST-001',
            pengirimNama: 'Pengirim Test',
            pengirimKota: 'Jakarta',
            penerimaNama: 'Penerima Test',
            penerimaKota: 'Bandung',
            serviceKode: 'REG',
            serviceNama: 'Reguler',
            courierNama: 'Kurir Test',
            courierCode: 'EXP-1',
            statusKode: 'CONFIRMED',
            statusNama: 'Dikonfirmasi',
            totalBiaya: 25000,
            metodePembayaran: 'QRIS',
            statusPembayaran: 'PAID',
            createdAt: DateTime.now(),
          ),
        ],
        totalCount: 1,
        currentPage: 1,
        pageSize: 10,
        totalPages: 1,
      );

  @override
  Future<AdminShipmentDetailModel> getShipmentDetail(int shipmentId) async => AdminShipmentDetailModel(
        id: shipmentId,
        nomorResi: 'SATSET-TEST-001',
        barcodeValue: 'SATSET-TEST-001',
        statusKode: 'DELIVERED',
        statusNama: 'Berhasil Terkirim',
        serviceKode: 'REG',
        serviceNama: 'Reguler',
        pengirimNama: 'Pengirim Test',
        pengirimNoHp: '0812345678',
        pengirimAlamat: 'Alamat Asal',
        pengirimKota: 'Jakarta',
        penerimaNama: 'Penerima Test',
        penerimaNoHp: '0898765432',
        penerimaAlamat: 'Alamat Tujuan',
        penerimaKota: 'Bandung',
        totalBeratGram: 1000,
        panjangCm: 10,
        lebarCm: 10,
        tinggiCm: 10,
        totalBarang: 1,
        biayaPengiriman: 25000,
        biayaAsuransi: 0,
        biayaLayananTambahan: 0,
        diskon: 0,
        totalBiaya: 25000,
        metodePembayaran: 'QRIS',
        statusPembayaran: 'PAID',
        createdAt: DateTime.now(),
        trackingHistory: const [],
      );

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() async => [];

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() async => [];

  @override
  Future<List<Map<String, dynamic>>> getCourierReferences() async => [];

  @override
  RealtimeChannel subscribeToRealtimeUpdates({required void Function() onDataChanged}) {
    throw UnimplementedError();
  }
}

class MockAdminDashboardRepository implements AdminDashboardRepository {
  final MockAdminDashboardRemoteDataSource remote = MockAdminDashboardRemoteDataSource();

  @override
  Future<bool> verifyAdminAccess() => remote.verifyAdminAccess();

  @override
  Future<AdminDashboardStats> getDashboardStats() => remote.getDashboardStats();

  @override
  Future<List<AdminCourierSummary>> getCourierSummaries() => remote.getCourierSummaries();

  @override
  Future<List<AdminActivity>> getRecentActivities({int limit = 10}) async => [];

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
  }) =>
      remote.getPaginatedShipments(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        serviceFilter: serviceFilter,
        courierIdFilter: courierIdFilter,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<AdminShipmentDetail> getShipmentDetail(int shipmentId) => remote.getShipmentDetail(shipmentId);

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() => remote.getStatusReferences();

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() => remote.getServiceTypeReferences();

  @override
  Future<List<Map<String, dynamic>>> getCourierReferences() => remote.getCourierReferences();
}

void main() {
  group('Admin Dashboard Formatters & Utils Tests', () {
    test('AdminCurrencyFormatter formats Rupiah correctly', () {
      expect(AdminCurrencyFormatter.formatRupiah(15000), 'Rp 15.000');
      expect(AdminCurrencyFormatter.formatRupiah(1500000), 'Rp 1.500.000');
      expect(AdminCurrencyFormatter.formatRupiah(0), 'Rp 0');
      expect(AdminCurrencyFormatter.formatRupiah(null), 'Rp 0');
      expect(AdminCurrencyFormatter.formatCompactRupiah(1500000), 'Rp 1.5 Jt');
    });

    test('AdminDateFormatter formats date and time cleanly', () {
      final date = DateTime(2026, 11, 2, 14, 30);
      expect(AdminDateFormatter.formatShortDate(date), '02 Nov 2026');
      expect(AdminDateFormatter.formatFullDate(date), '02 November 2026');
      expect(AdminDateFormatter.formatDateTime(date), '02 Nov 2026, 14:30 WIB');
    });

    test('AdminStatusHelper maps labels and colors correctly', () {
      expect(AdminStatusHelper.getStatusLabel('DELIVERED'), 'Berhasil Terkirim');
      expect(AdminStatusHelper.getStatusLabel('PENDING'), 'Menunggu Konfirmasi');
      expect(AdminStatusHelper.getStatusLabel('FAILED_DELIVERY'), 'Gagal Terkirim');
      expect(AdminStatusHelper.getPaymentStatusLabel('PAID'), 'Lunas');
    });
  });

  group('Admin Dashboard Models Tests', () {
    test('AdminShipmentTableModel parses data correctly', () {
      final map = {
        'id': 10,
        'nomor_resi': 'SATSET-12345',
        'barcode_value': 'SATSET-12345',
        'pengirim_nama': 'Budi',
        'pengirim_kota': 'Jakarta',
        'penerima_nama': 'Siti',
        'penerima_kota': 'Surabaya',
        'total_biaya': 45000,
        'created_at': DateTime.now().toIso8601String(),
        'm_shipment_statuses': {'kode': 'IN_TRANSIT', 'nama_status': 'Dalam Pengiriman'},
        'm_service_types': {'kode': 'EXP', 'nama_layanan': 'Express'},
      };

      final model = AdminShipmentTableModel.fromMap(map);
      expect(model.id, 10);
      expect(model.nomorResi, 'SATSET-12345');
      expect(model.statusKode, 'IN_TRANSIT');
      expect(model.serviceNama, 'Express');
      expect(model.totalBiaya, 45000);
    });

    test('AdminActivityModel parses activity correctly', () {
      final map = {
        'id': 5,
        'shipment_id': 10,
        'catatan': 'Paket tiba di sorting hub',
        'lokasi_nama': 'Hub Cakung',
        'created_at': DateTime.now().toIso8601String(),
        't_shipments': {'id': 10, 'nomor_resi': 'SATSET-12345'},
        'm_shipment_statuses': {'kode': 'AT_SORTING_CENTER', 'nama_status': 'Sorting Center'},
      };

      final act = AdminActivityModel.fromMap(map);
      expect(act.shipmentId, 10);
      expect(act.nomorResi, 'SATSET-12345');
      expect(act.statusCode, 'AT_SORTING_CENTER');
    });
  });

  group('Admin Dashboard Bloc Tests', () {
    test('AdminDashboardBloc handles started and trends period changed', () async {
      final mockRepo = MockAdminDashboardRepository();
      final mockDS = MockAdminDashboardRemoteDataSource();

      final bloc = AdminDashboardBloc(
        repository: mockRepo,
        remoteDataSource: mockDS,
      );

      expect(bloc.state.status, AdminDashboardStatus.initial);

      bloc.add(const AdminDashboardTrendPeriodChanged('WEEKLY'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeTrendPeriod, 'WEEKLY');

      await bloc.close();
    });
  });
}
