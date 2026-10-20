// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:satset/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:satset/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:satset/features/auth/domain/usecases/login_usecase.dart';
import 'package:satset/features/auth/domain/usecases/logout_usecase.dart';
import 'package:satset/features/auth/domain/usecases/register_usecase.dart';
import 'package:satset/features/auth/presentation/pages/login_page.dart';
import 'package:satset/features/auth/presentation/widgets/login_form.dart';
import 'package:satset/features/splash/presentation/pages/splash_page.dart';
import 'package:satset/features/splash/presentation/widgets/splash_logo.dart';
import 'package:satset/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads splash first, then navigates to login page',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final localDataSource = AuthLocalDataSourceImpl();
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final loginUseCase = LoginUseCase(authRepository);
    final registerUseCase = RegisterUseCase(authRepository);
    final logoutUseCase = LogoutUseCase(authRepository);
    final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

    // 1. Build app and trigger frame pertama
    await tester.pumpWidget(
      SatSetApp(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        logoutUseCase: logoutUseCase,
        getCurrentUserUseCase: getCurrentUserUseCase,
        authRepository: authRepository,
      ),
    );

    // Verifikasi Tahap 1: Pertama kali yang muncul HARUS Splash Screen Logo
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(SplashLogo), findsOneWidget);

    // 2. Beri waktu timer logo splash (1500ms) berjalan
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Verifikasi Tahap 2: Splash Onboarding HARUS dimulai dari slide pertama (Page 0), BUKAN halaman terakhir
    expect(find.text('Delivery to your home'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text("Let's Go"), findsNothing); // Pastikan BUKAN halaman terakhir

    // 3. Tekan tombol Skip untuk menyelesaikan splash & onboarding menuju Login
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verifikasi Tahap 3: Berpindah ke Halaman Login dan TIDAK muncul popup 'Login Berhasil' secara tiba-tiba
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Login Berhasil! 🎉'), findsNothing);
    expect(find.byType(LoginForm), findsOneWidget);

    // Verifikasi Tahap 4: Uji Hot Reload / Reset Aplikasi
    // Saat di-reload/reset, aplikasi HARUS kembali ke Splash Screen & logo dari awal!
    tester.state<SatSetAppState>(find.byType(SatSetApp)).resetToSplash();
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(SplashLogo), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Beri waktu timer logo splash kedua (1500ms)
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Verifikasi kembali berada di slide pertama (Page 0), BUKAN halaman terakhir!
    expect(find.text('Delivery to your home'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text("Let's Go"), findsNothing);
  });
}


