import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/account/domain/entities/user_account.dart';
import 'package:satset/features/account/presentation/pages/edit_account_page.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('EditAccountPage Dual-Table & id_users_roles Tests', () {
    testWidgets(
        'renders customer profile with prefilled name, email, and phone',
        (tester) async {
      const customerUser = User(
        id: 'usr_003',
        name: 'Ahmad Pelanggan',
        email: 'ahmad@satset.id',
        phone: '081234567890',
        idUsersRole: 3,
        role: 'customer',
      );

      const customerAccount = UserAccount(
        id: 'usr_003',
        name: 'Ahmad Pelanggan',
        email: 'ahmad@satset.id',
        phone: '081234567890',
        membershipTier: 'SatSet Priority Member',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          const EditAccountPage(
            user: customerUser,
            account: customerAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan judul halaman tampil
      expect(find.text('Edit Akun'), findsOneWidget);

      // Memastikan field Nama, Email, dan No HP terisi
      expect(find.text('Ahmad Pelanggan'), findsWidgets);
      expect(find.text('ahmad@satset.id'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);

      // Memastikan bagian teks 'Sinkronisasi Supabase' dan badge '(Role' telah dihapus
      expect(find.textContaining('Sinkronisasi Supabase'), findsNothing);
      expect(find.textContaining('(Role:'), findsNothing);
    });

    testWidgets(
        'renders courier profile with prefilled name, email, and phone',
        (tester) async {
      const courierUser = User(
        id: 'emp_002',
        name: 'Budi Kurir SatSet',
        email: 'budi.courier@satset.id',
        phone: '081987654321',
        idUsersRole: 2,
        role: 'courier',
      );

      const courierAccount = UserAccount(
        id: 'emp_002',
        name: 'Budi Kurir SatSet',
        email: 'budi.courier@satset.id',
        phone: '081987654321',
        membershipTier: 'Mitra Kurir SatSet: 002',
        isCourier: true,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          const EditAccountPage(
            user: courierUser,
            account: courierAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan field Nama, Email, dan No HP kurir terisi
      expect(find.text('Budi Kurir SatSet'), findsWidgets);
      expect(find.text('budi.courier@satset.id'), findsOneWidget);
      expect(find.text('081987654321'), findsOneWidget);

      // Memastikan bagian teks 'Sinkronisasi Supabase' dan badge '(Role' telah dihapus
      expect(find.textContaining('Sinkronisasi Supabase'), findsNothing);
      expect(find.textContaining('(Role:'), findsNothing);
    });

    testWidgets('triggers validation errors when fields are empty or invalid',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createWidgetUnderTest(
          const EditAccountPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol Simpan Perubahan dan scroll ke tombol
      final saveButton = find.text('Simpan Perubahan');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Harus muncul pesan validasi error
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
      expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    });

    testWidgets('back button pops the page without saving', (tester) async {
      bool? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.of(context).push<bool?>(
                    EditAccountPage.route(),
                  );
                },
                child: const Text('Open Edit Account'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Account'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Akun'), findsOneWidget);

      // Tekan tombol kembali
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit Akun'), findsNothing);
      expect(popResult, isFalse);
    });
  });
}
