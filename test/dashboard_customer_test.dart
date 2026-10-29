import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/customer/dashboard/data/models/shipment_model.dart';
import 'package:satset/features/customer/dashboard/data/models/user_profile_model.dart';
import 'package:satset/features/customer/dashboard/domain/entities/user_profile.dart';
import 'package:satset/features/customer/dashboard/domain/entities/shipment.dart';
import 'package:satset/features/customer/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:satset/features/customer/dashboard/presentation/widgets/dashboard_skeleton.dart';

void main() {
  group('Dashboard Customer Supabase Data Models & Entity Tests', () {
    test('UserProfileModel.fromDatabase parses m_users row correctly', () {
      final dbRow = {
        'id': 4,
        'nama_lengkap': 'Ahmad Pelanggan',
        'email': 'ahmad@satset.id',
        'no_hp': '081234567890',
        'alamat_lengkap': 'Kebayoran Baru, Jakarta Selatan',
        'latitude': -6.2415,
        'longitude': 106.8000,
        'photo_url': null,
      };

      final profile = UserProfileModel.fromDatabase(dbRow);

      expect(profile.id, '4');
      expect(profile.name, 'Ahmad Pelanggan');
      expect(profile.email, 'ahmad@satset.id');
      expect(profile.phone, '081234567890');
      expect(profile.currentCity, 'Jakarta Selatan');
      expect(profile.currentSubdistrict, 'Kebayoran Baru');
      expect(profile.currentLatitude, -6.2415);
      expect(profile.currentLongitude, 106.8000);
      expect(profile.greetingDisplay, contains('Ahmad Pelanggan'));
    });

    test('ShipmentModel.fromDatabase parses t_shipments with joins correctly', () {
      final shipmentRow = {
        'id': 101,
        'nomor_resi': 'SST-20261021-001',
        'barcode_value': 'SST-20261021-001',
        'customer_id': 4,
        'service_type_id': 2,
        'status_id': 5,
        'pengirim_nama': 'Toko Sepatu SatSet',
        'pengirim_no_hp': '081122334455',
        'pengirim_alamat': 'Jl. Asia Afrika No. 1',
        'pengirim_kota': 'Jakarta Pusat',
        'penerima_nama': 'Budi Santoso',
        'penerima_no_hp': '089988776655',
        'penerima_alamat': 'Jl. Fatmawati No. 45',
        'penerima_kota': 'Jakarta Selatan',
        'total_berat_gram': 1200,
        'total_barang': 1,
        'total_biaya': 24000.0,
        'metode_pembayaran': 'QRIS',
        'estimasi_tiba': '2026-10-21T16:00:00Z',
        'created_at': '2026-10-21T10:00:00Z',
        'updated_at': '2026-10-21T11:00:00Z',
        'm_shipment_statuses': {
          'id': 5,
          'kode': 'IN_TRANSIT',
          'nama_status': 'Dalam Perjalanan',
        },
        'm_service_types': {
          'id': 2,
          'kode': 'EXP',
          'nama_layanan': 'Express',
        },
        't_shipment_tracking': [
          {
            'id': 1,
            'shipment_id': 101,
            'status_id': 1,
            'lokasi_nama': 'Hub Jakarta Pusat',
            'latitude': -6.1900,
            'longitude': 106.8200,
            'catatan': 'Paket diterima di Hub',
            'created_at': '2026-10-21T10:15:00Z',
          },
          {
            'id': 2,
            'shipment_id': 101,
            'status_id': 5,
            'lokasi_nama': 'Jl. Sudirman',
            'latitude': -6.2200,
            'longitude': 106.8150,
            'catatan': 'Kurir sedang membawa paket menuju alamat penerima',
            'created_at': '2026-10-21T11:00:00Z',
          },
        ],
      };

      final shipment = ShipmentModel.fromDatabase(shipmentRow);

      expect(shipment.id, '101');
      expect(shipment.nomorResi, 'SST-20261021-001');
      expect(shipment.customerId, 4);
      expect(shipment.serviceName, 'Express');
      expect(shipment.statusName, 'Dalam Perjalanan');
      expect(shipment.statusCode, 'IN_TRANSIT');
      expect(shipment.isInTransit, isTrue);
      expect(shipment.isDelivered, isFalse);
      expect(shipment.totalBeratGram, 1200);
      expect(shipment.formattedTotalBerat, '1.2 kg');
      expect(shipment.formattedTotalBiaya, 'Rp 24.000');
      expect(shipment.timeline.length, 2);
      expect(shipment.timeline.last.location, 'Jl. Sudirman');
      expect(shipment.courier, isNotNull);
      expect(shipment.courierPosition?.latitude, -6.2200);
    });

    test('ShipmentStatusSummary computes counts correctly', () {
      const summary = ShipmentStatusSummary(
        waitingConfirmationCount: 2,
        inProcessCount: 3,
        inTransitCount: 1,
        deliveredCount: 5,
      );

      expect(summary.totalShipments, 11);
      expect(summary.waitingConfirmationCount, 2);
      expect(summary.inProcessCount, 3);
      expect(summary.inTransitCount, 1);
      expect(summary.deliveredCount, 5);
    });

    testWidgets('DashboardSkeleton renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeleton(),
          ),
        ),
      );

      expect(find.byType(DashboardSkeleton), findsOneWidget);
    });

    test('UserProfile.currentLocationDisplay returns current city & subdistrict instead of street address', () {
      const profile = UserProfile(
        id: '1',
        name: 'Budi Santoso',
        alamatLengkap: 'Jl. Sudirman No. 12, RT 01 / RW 04, Menteng',
        currentCity: 'Jakarta Pusat',
        currentSubdistrict: 'Menteng',
      );

      expect(profile.currentLocationDisplay, 'Menteng, Jakarta Pusat');
      expect(profile.locationDisplay, 'Menteng, Jakarta Pusat');
      expect(profile.locationDisplay, isNot(contains('Jl. Sudirman')));
    });

    testWidgets('DashboardHeader renders current location with GPS icon instead of street address', (tester) async {
      const profile = UserProfile(
        id: '1',
        name: 'Budi Santoso',
        alamatLengkap: 'Jl. Sudirman No. 12, RT 01 / RW 04, Menteng',
        currentCity: 'Jakarta Pusat',
        currentSubdistrict: 'Menteng',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardHeader(
              profile: profile,
              onNotificationTap: () {},
            ),
          ),
        ),
      );

      // Pastikan ada teks lokasi atau tooltip Lokasi Sekarang
      expect(find.byTooltip('Lokasi Sekarang'), findsOneWidget);
      // Pastikan teks mengandung nama wilayah lokasi sekarang
      expect(find.textContaining('Jakarta Pusat'), findsOneWidget);
      // Pastikan alamat jalan panjang tidak muncul di header
      expect(find.textContaining('Jl. Sudirman'), findsNothing);
      // Pastikan ikon lokasi ditampilkan
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });
  });
}
