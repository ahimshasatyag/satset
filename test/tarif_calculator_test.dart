import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/customer/dashboard/presentation/widgets/tarif_calculator_sheet.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';

void main() {
  group('TarifCalculatorSheet Tests', () {
    const testCities = [
      Regency(
        code: '31.74',
        provinceCode: '31',
        name: 'Kota Jakarta Selatan',
        type: 'KOTA',
      ),
      Regency(
        code: '32.73',
        provinceCode: '32',
        name: 'Kota Bandung',
        type: 'KOTA',
      ),
      Regency(
        code: '35.78',
        provinceCode: '35',
        name: 'Kota Surabaya',
        type: 'KOTA',
      ),
    ];

    testWidgets('renders calculator with 1 km = Rp 6.000 base rate correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarifCalculatorSheet(
              initialCities: testCities,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan judul dan banner tarif muncul
      expect(find.text('Kalkulator Cek Ongkir'), findsOneWidget);
      expect(find.text('Tarif Dasar: Rp 6.000 / 1 km'), findsOneWidget);

      // Memastikan rute awal kota ke kota (m_kabkot)
      expect(find.text('Kota Jakarta Selatan ➔ Kota Bandung'), findsOneWidget);

      // Memastikan nilai default 1 Km dan 1 Kg
      expect(find.text('1 Km'), findsWidgets);
      expect(find.text('1 Kg'), findsOneWidget);

      // Memastikan tarif dasar layanan untuk 1 km:
      // 1. Reguler: 1 km * Rp 6.000 = Rp 6.000
      expect(find.text('Rp 6.000'), findsWidgets);

      // 2. Sameday: 1 km * Rp 6.000 * 1.3 = Rp 7.800
      expect(find.text('Rp 7.800'), findsOneWidget);

      // 3. Instant: 1 km * Rp 6.000 * 1.6 = Rp 9.600
      expect(find.text('Rp 9.600'), findsOneWidget);
    });

    testWidgets('swapping route origin and destination updates route display', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarifCalculatorSheet(
              initialCities: testCities,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kota Jakarta Selatan ➔ Kota Bandung'), findsOneWidget);

      // Klik tombol "Tukar Rute"
      final swapButton = find.text('Tukar Rute');
      expect(swapButton, findsOneWidget);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      // Sekarang rutenya tertukar: Kota Bandung ➔ Kota Jakarta Selatan
      expect(find.text('Kota Bandung ➔ Kota Jakarta Selatan'), findsOneWidget);
    });

    testWidgets('changing distance via chips updates tariff reactively', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarifCalculatorSheet(
              initialCities: testCities,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Klik chip 5 Km
      final fiveKmChip = find.widgetWithText(ActionChip, '5 Km');
      expect(fiveKmChip, findsOneWidget);
      await tester.ensureVisible(fiveKmChip);
      await tester.tap(fiveKmChip);
      await tester.pumpAndSettle();

      // Perhitungan tarif untuk 5 km:
      // Reguler: 5 km * Rp 6.000 = Rp 30.000
      expect(find.text('Rp 30.000'), findsOneWidget);

      // Sameday: 5 km * Rp 6.000 * 1.3 = Rp 39.000
      expect(find.text('Rp 39.000'), findsOneWidget);

      // Instant: 5 km * Rp 6.000 * 1.6 = Rp 48.000
      expect(find.text('Rp 48.000'), findsOneWidget);
    });

    testWidgets('clicking Lanjutkan Buat Pesanan calls onCreateShipment callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool shipmentCreated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarifCalculatorSheet(
              initialCities: testCities,
              onCreateShipment: () {
                shipmentCreated = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final createOrderButton = find.text('Lanjutkan Buat Pesanan (+ Kirim)');
      expect(createOrderButton, findsOneWidget);
      await tester.ensureVisible(createOrderButton);
      await tester.tap(createOrderButton);
      await tester.pumpAndSettle();

      expect(shipmentCreated, isTrue);
    });
  });
}
