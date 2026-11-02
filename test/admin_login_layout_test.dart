import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_login_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/admin_logout_usecase.dart';
import 'package:satset/features/admin/auth/domain/usecases/get_current_admin_usecase.dart';
import 'package:satset/features/admin/auth/presentation/bloc/admin_auth_bloc.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'admin_auth_test.dart';

void main() {
  group('AdminLoginView Responsiveness & Layout Tests', () {
    late MockAdminAuthRepository repo;
    late AdminAuthBloc bloc;

    setUp(() {
      repo = MockAdminAuthRepository();
      bloc = AdminAuthBloc(
        loginUseCase: AdminLoginUseCase(repo),
        getCurrentAdminUseCase: GetCurrentAdminUseCase(repo),
        logoutUseCase: AdminLogoutUseCase(repo),
        repository: repo,
      );
    });

    testWidgets('Renders on desktop without layout errors', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AdminAuthBloc>.value(
            value: bloc,
            child: const AdminLoginView(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Masuk ke Panel Kendali'), findsOneWidget);
      expect(find.text('PORTAL ADMINISTRATOR'), findsNWidgets(2));
    });

    testWidgets('Renders on mobile/tablet without layout errors', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AdminAuthBloc>.value(
            value: bloc,
            child: const AdminLoginView(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Masuk ke Panel Kendali'), findsOneWidget);
    });
  });
}
