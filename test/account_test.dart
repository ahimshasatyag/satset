import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/account/data/datasources/account_local_datasource.dart';
import 'package:satset/features/account/data/datasources/account_remote_datasource.dart';
import 'package:satset/features/account/data/models/user_account_model.dart';
import 'package:satset/features/account/data/repositories/account_repository_impl.dart';
import 'package:satset/features/account/domain/entities/user_account.dart';
import 'package:satset/features/account/domain/usecases/get_user_account_usecase.dart';
import 'package:satset/features/account/domain/usecases/logout_account_usecase.dart';
import 'package:satset/features/account/presentation/bloc/account_bloc.dart';
import 'package:satset/features/account/presentation/bloc/account_event.dart';
import 'package:satset/features/account/presentation/bloc/account_state.dart';
import 'package:satset/features/account/presentation/pages/account_page.dart';
import 'package:satset/features/account/presentation/widgets/account_skeleton.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Clean Architecture Unit Tests', () {
    late AccountRemoteDataSource remoteDataSource;
    late AccountLocalDataSource localDataSource;
    late AccountRepositoryImpl repository;
    late GetUserAccountUseCase getUserAccountUseCase;
    late LogoutAccountUseCase logoutAccountUseCase;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      remoteDataSource = AccountRemoteDataSourceImpl();
      localDataSource = AccountLocalDataSourceImpl();
      repository = AccountRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      getUserAccountUseCase = GetUserAccountUseCase(repository);
      logoutAccountUseCase = LogoutAccountUseCase(repository);
    });

    test('UserAccountModel serialization works properly', () {
      const model = UserAccountModel(
        id: 'usr-99',
        name: 'John SatSet',
        email: 'john@satset.id',
        phone: '08123456789',
        membershipTier: 'Priority Gold',
        satsetPayBalance: 750000,
      );

      final json = model.toJson();
      expect(json['name'], equals('John SatSet'));
      expect(json['satsetPayBalance'], equals(750000));

      final reconstructed = UserAccountModel.fromJson(json);
      expect(reconstructed.id, equals(model.id));
      expect(reconstructed.email, equals(model.email));
      expect(reconstructed.membershipTier, equals(model.membershipTier));
    });

    test('UserAddressModel serialization and deserialization works properly', () {
      const address = UserAddressModel(
        id: 'addr-01',
        label: 'Kantor SatSet',
        receiverName: 'Ahmad Satria',
        phone: '081234567890',
        provinceCode: '31',
        provinceName: 'DKI JAKARTA',
        regencyCode: '31.01',
        regencyName: 'Kota Jakarta Pusat',
        districtCode: '31.01.01',
        districtName: 'Gambir',
        villageCode: '31.01.01.1001',
        villageName: 'Gambir',
        postalCode: '10110',
        fullAddress: 'Jl. Medan Merdeka Barat No. 1',
        isPrimary: true,
      );

      final json = address.toJson();
      expect(json['label'], equals('Kantor SatSet'));
      expect(json['isPrimary'], isTrue);

      final reconstructed = UserAddressModel.fromJson(json);
      expect(reconstructed.id, equals(address.id));
      expect(reconstructed.fullAddress, equals(address.fullAddress));
      expect(reconstructed.postalCode, equals('10110'));
    });

    test('AccountRepository gets user account and saves to local cache', () async {
      final account = await repository.getUserAccount();
      expect(account.name, equals('Satria Perkasa'));
      expect(account.satsetPayBalance, equals(450000));

      // Verifikasi tersimpan di cache
      final cached = await localDataSource.getSavedAccount();
      expect(cached, isNotNull);
      expect(cached!.email, equals(account.email));
    });

    test('AccountRepository handles address management (add, primary, delete)', () async {
      const addr1 = UserAddress(
        id: 'addr-01',
        label: 'Rumah',
        receiverName: 'Satria',
        phone: '081234567890',
        fullAddress: 'Jl. Mawar Indah No. 5',
        isPrimary: true,
      );
      const addr2 = UserAddress(
        id: 'addr-02',
        label: 'Kantor',
        receiverName: 'Satria Work',
        phone: '081234567891',
        fullAddress: 'Gedung SatSet Lt. 7',
        isPrimary: false,
      );

      // 1. Simpan addr1
      await repository.saveAddress(addr1);
      var addresses = await repository.getAddresses();
      expect(addresses.length, equals(1));
      expect(addresses.first.isPrimary, isTrue);

      // 2. Simpan addr2
      await repository.saveAddress(addr2);
      addresses = await repository.getAddresses();
      expect(addresses.length, equals(2));

      // 3. Set addr2 sebagai primary
      await repository.setPrimaryAddress('addr-02');
      addresses = await repository.getAddresses();
      final p2 = addresses.firstWhere((a) => a.id == 'addr-02');
      final p1 = addresses.firstWhere((a) => a.id == 'addr-01');
      expect(p2.isPrimary, isTrue);
      expect(p1.isPrimary, isFalse);

      // 4. Hapus addr1
      await repository.deleteAddress('addr-01');
      addresses = await repository.getAddresses();
      expect(addresses.length, equals(1));
      expect(addresses.first.id, equals('addr-02'));
    });

    test('AccountBloc loads profile, toggles notifications, updates profile, and logs out', () async {
      final bloc = AccountBloc(
        getUserAccountUseCase: getUserAccountUseCase,
        logoutAccountUseCase: logoutAccountUseCase,
        repository: repository,
      );

      // Tunggu state loaded awal
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AccountState>((s) => s.account != null && !s.isLoading),
        ),
      );

      expect(bloc.state.account!.name, equals('Satria Perkasa'));

      // Uji update profil
      bloc.add(const AccountProfileUpdated(
        name: 'Satria Wijaya',
        phone: '+62 899-9999-9999',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AccountState>((s) =>
              s.account?.name == 'Satria Wijaya' &&
              s.actionSuccessMessage != null),
        ),
      );

      // Uji toggle notifikasi
      bloc.add(const AccountNotificationsToggled(false));
      await expectLater(
        bloc.stream,
        emits(
          predicate<AccountState>((s) =>
              s.account?.isNotificationsEnabled == false),
        ),
      );

      // Uji resend email verification
      bloc.add(const AccountEmailVerificationResent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AccountState>((s) =>
              s.actionSuccessMessage?.contains('verifikasi') == true),
        ),
      );

      // Uji logout
      bloc.add(const AccountLogoutSubmitted());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AccountState>((s) => s.isLoggedOut == true),
        ),
      );

      await bloc.close();
    });

    testWidgets('AccountPage renders without errors and shows customer profile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccountPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Satria Perkasa'), findsOneWidget);
      expect(find.text('Alamat Pengiriman Saya'), findsOneWidget);
      expect(find.text('Kredensial & Kata Sandi'), findsOneWidget);
      // Scroll sampai menemukan menu Tema Tampilan
      await tester.scrollUntilVisible(
        find.text('Tema Tampilan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Tema Tampilan'), findsOneWidget);

      // Buka dialog tema
      await tester.tap(find.text('Tema Tampilan'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Tema Tampilan'), findsOneWidget);
      expect(find.text('Mode Terang (Light Theme)'), findsOneWidget);
      expect(find.text('Mode Gelap (Dark Theme)'), findsOneWidget);
    });

    test('AccountRemoteDataSource handles courier account properly', () async {
      const courierUser = User(
        id: 'emp-001',
        name: 'Sandi Courier',
        email: 'sandi@satset.id',
        phone: '08123456789',
        role: 'courier',
        idUsersRole: 2,
        alamatLengkap: 'Pangkalan Pos SatSet Barat',
      );

      final courierRemote = AccountRemoteDataSourceImpl(currentUser: courierUser);
      final account = await courierRemote.getUserAccount();

      expect(account.id, equals('emp-001'));
      expect(account.name, equals('Sandi Courier'));
      expect(account.email, equals('sandi@satset.id'));
      expect(account.phone, equals('08123456789'));
      expect(account.isCourierAccount, isTrue);
      expect(account.membershipTier, contains('Mitra Kurir SatSet'));
      expect(account.fullAddress, equals('Pangkalan Pos SatSet Barat'));
    });

    testWidgets('AccountPage renders correctly for courier account', (tester) async {
      const courierUser = User(
        id: 'emp-001',
        name: 'Sandi Courier',
        email: 'sandi@satset.id',
        phone: '08123456789',
        role: 'courier',
        idUsersRole: 2,
        alamatLengkap: 'Pangkalan Pos SatSet Barat',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountPage(user: courierUser),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sandi Courier'), findsOneWidget);
      expect(find.text('sandi@satset.id'), findsOneWidget);
      expect(find.text('Operasional & Tugas Kurir'), findsNothing);
      expect(find.text('Pengiriman & Alamat'), findsNothing);
      expect(find.text('Keamanan Akun'), findsOneWidget);
      expect(find.text('Pengaturan dan Bantuan'), findsOneWidget);
    });

    testWidgets('AccountSkeleton renders customer and courier variants properly', (tester) async {
      // 1. Variant Customer
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountSkeleton(isCourier: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AccountSkeleton), findsOneWidget);

      // 2. Variant Courier
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountSkeleton(isCourier: true),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AccountSkeleton), findsOneWidget);
    });
  });
}
