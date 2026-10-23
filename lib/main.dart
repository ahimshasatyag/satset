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
import 'features/auth/domain/entities/user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/customer/dashboard/presentation/pages/dashboard_page.dart';
import 'features/courier/tasks/presentation/pages/courier_tasks_page.dart';
import 'features/main_navigation/presentation/pages/main_navigation_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'shared/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Daftarkan Bloc Observer untuk pemantauan state & error
  Bloc.observer = AppBlocObserver();

  // Inisialisasi Supabase
  await SupabaseConfig.initialize();

  // Bersihkan sesi Supabase yang kadaluarsa jika ada
  try {
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null && session.isExpired) {
      await SupabaseConfig.client.auth.signOut();
    }
  } catch (_) {}

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
  String? _userToken;
  User? _currentUser;

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
                onLoginSuccess: (user) {
                  if (mounted) {
                    setState(() {
                      _userToken = user.token;
                      _currentUser = user;
                      if (user.idUsersRole == 2 || user.role == 'courier') {
                        _currentRoute = '/courier/tasks';
                      } else {
                        _currentRoute = '/dashboard';
                      }
                    });
                  }
                },
              );
              break;
            case '/courier/tasks':
              homeWidget = CourierMainNavigationPage(
                user: _currentUser,
                token: _userToken,
              );
              break;
            case '/dashboard':
            case '/home':
              homeWidget = DashboardPage(
                token: _userToken,
                user: _currentUser,
              );
              break;
            case '/':
            default:
              homeWidget = SplashPage(
                onNavigateToLogin: () => _navigateTo('/login'),
                onNavigateToHome: () => _navigateTo('/dashboard'),
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
                    onLoginSuccess: (user) {
                      if (mounted) {
                        setState(() {
                          _userToken = user.token;
                          _currentUser = user;
                          if (user.idUsersRole == 2 || user.role == 'courier') {
                            _currentRoute = '/courier/tasks';
                          } else {
                            _currentRoute = '/dashboard';
                          }
                        });
                      }
                    },
                  ),
              '/courier/tasks': (context) => CourierMainNavigationPage(
                    user: _currentUser,
                    token: _userToken,
                  ),
              '/dashboard': (context) => DashboardPage(
                    token: _userToken,
                    user: _currentUser,
                  ),
              '/home': (context) => DashboardPage(
                    token: _userToken,
                    user: _currentUser,
                  ),
              '/notifications': (context) => const NotificationsPage(),
            },
          );
        },
      ),
    );
  }
}
