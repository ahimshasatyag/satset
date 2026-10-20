import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/account/data/datasources/account_local_datasource.dart';
import 'package:satset/features/account/data/datasources/account_remote_datasource.dart';
import 'package:satset/features/account/data/models/user_account_model.dart';
import 'package:satset/features/account/data/repositories/account_repository_impl.dart';
import 'package:satset/features/account/domain/usecases/get_user_account_usecase.dart';
import 'package:satset/features/account/domain/usecases/logout_account_usecase.dart';
import 'package:satset/features/account/presentation/bloc/account_bloc.dart';
import 'package:satset/features/account/presentation/bloc/account_event.dart';
import 'package:satset/features/account/presentation/bloc/account_state.dart';
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

    test('AccountRepository gets user account and saves to local cache', () async {
      final account = await repository.getUserAccount();
      expect(account.name, equals('Satria Perkasa'));
      expect(account.satsetPayBalance, equals(450000));

      // Verifikasi tersimpan di cache
      final cached = await localDataSource.getSavedAccount();
      expect(cached, isNotNull);
      expect(cached!.email, equals(account.email));
    });

    test('AccountBloc loads profile and toggles notifications', () async {
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

      // Uji toggle notifikasi
      bloc.add(const AccountNotificationsToggled(false));
      await expectLater(
        bloc.stream,
        emits(
          predicate<AccountState>((s) =>
              s.account?.isNotificationsEnabled == false),
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
  });
}
