import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/config/supabase_config.dart';
import 'app/observers/app_bloc_observer.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'shared/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Daftarkan Bloc Observer untuk pemantauan state & error
  Bloc.observer = AppBlocObserver();

  // Inisialisasi Supabase
  await SupabaseConfig.initialize();

  // Inisialisasi dependensi
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

  runApp(
    SatSetApp(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      authRepository: authRepository,
    ),
  );
}

class SatSetApp extends StatefulWidget {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  const SatSetApp({
    super.key,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  });

  @override
  State<SatSetApp> createState() => SatSetAppState();
}

class SatSetAppState extends State<SatSetApp> {
  Key _appKey = UniqueKey();
  String _currentRoute = '/';

  /// Me-reset rute aplikasi kembali ke Splash Screen (SplashPage)
  void resetToSplash() {
    if (mounted) {
      setState(() {
        _currentRoute = '/';
        _appKey = UniqueKey();
      });
    }
  }


  void _navigateTo(String route) {
    if (mounted) {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      key: _appKey,
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: widget.loginUseCase,
            registerUseCase: widget.registerUseCase,
            logoutUseCase: widget.logoutUseCase,
            getCurrentUserUseCase: widget.getCurrentUserUseCase,
            repository: widget.authRepository,
          ),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          Widget homeWidget;
          switch (_currentRoute) {
            case '/login':
              homeWidget = LoginPage(
                onLoginSuccess: (_) => _navigateTo('/home'),
              );
              break;
            case '/home':
              homeWidget = ThemePreviewPage(
                onResetToSplash: () => resetToSplash(),
              );
              break;
            case '/':
            default:
              homeWidget = SplashPage(
                onNavigateToLogin: () => _navigateTo('/login'),
                onNavigateToHome: () => _navigateTo('/home'),
              );
              break;
          }

          return MaterialApp(
            key: _appKey,
            title: 'SatSet.id',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: homeWidget,
            routes: {
              '/login': (context) => LoginPage(
                    onLoginSuccess: (_) => _navigateTo('/home'),
                  ),
              '/home': (context) => ThemePreviewPage(
                    onResetToSplash: () => resetToSplash(),
                  ),
            },
          );
        },
      ),
    );
  }
}
