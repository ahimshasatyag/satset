import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/social_login_buttons.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'courier_register_page.dart';

import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/features/customer/dashboard/presentation/pages/dashboard_page.dart';
import 'package:satset/features/main_navigation/presentation/pages/main_navigation_page.dart';

/// Halaman Login Utama SatSet
class LoginPage extends StatelessWidget {
  final void Function(User user)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<AuthBloc>();
      return LoginView(onLoginSuccess: onLoginSuccess);
    } catch (_) {
      final localDataSource = AuthLocalDataSourceImpl();
      final remoteDataSource = AuthRemoteDataSourceImpl();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      return BlocProvider(
        create: (context) => AuthBloc(
          loginUseCase: LoginUseCase(repository),
          registerUseCase: RegisterUseCase(repository),
          logoutUseCase: LogoutUseCase(repository),
          getCurrentUserUseCase: GetCurrentUserUseCase(repository),
          repository: repository,
        )..add(const AuthCheckRequested()),
        child: LoginView(onLoginSuccess: onLoginSuccess),
      );
    }
  }
}

class LoginView extends StatefulWidget {
  final void Function(User user)? onLoginSuccess;

  const LoginView({super.key, this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _userInitiatedLogin = false;
  bool _isCheckingLocation = false;
  String? _loadingStatusText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state is AuthSuccess) {
          authBloc.add(const AuthResetState());
        }
        // Bersihkan sesi Supabase yang kadaluarsa di penyimpanan lokal
        try {
          final session = SupabaseConfig.client.auth.currentSession;
          if (session != null && session.isExpired) {
            await SupabaseConfig.client.auth.signOut();
          }
        } catch (_) {}
      }
    });
  }

  bool _hasPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage('assets/images/Background.png'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background motif dari Background.png dengan gaplessPlayback agar tidak sempat hilang saat rebuild
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // Lapisan overlay halus untuk mode gelap agar teks & card tetap kontras optimal
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess && _userInitiatedLogin) {
                _userInitiatedLogin = false;
                bool hasNavigated = false;
                void go() {
                  if (!hasNavigated && mounted) {
                    hasNavigated = true;
                    _navigateToRoleDestination(context, state.user);
                  }
                }

                final isCourier =
                    state.user.idUsersRole == 2 || state.user.role == 'courier';
                CustomDialog.showSuccess(
                  context: context,
                  title: 'Login Berhasil! 🎉',
                  message: state.message,
                  confirmText: isCourier
                      ? 'Buka Tugas Kurir'
                      : 'Lanjutkan ke Dashboard',
                  onConfirm: go,
                ).then((_) => go());
              } else if (state is AuthFailure && _userInitiatedLogin) {
                _userInitiatedLogin = false;
                CustomDialog.showError(
                  context: context,
                  title: 'Gagal Masuk',
                  message: state.errorMessage,
                  confirmText: 'Coba Lagi',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final savedEmail = state is AuthUnauthenticated
                  ? state.savedEmail
                  : null;
              final isRememberMe = state is AuthUnauthenticated
                  ? state.rememberMe
                  : false;

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo Brand SatSet
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/LogoTextSatset.png',
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Judul Halaman
                          Center(
                            child: Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          CustomCard(
                            variant: CardVariant.elevated,
                            padding: const EdgeInsets.all(20),
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Login (Email, Password, Remember Me, Submit)
                                LoginForm(
                                  initialEmail: savedEmail,
                                  initialRememberMe: isRememberMe,
                                  isLoading: isLoading || _isCheckingLocation,
                                  loadingText: _loadingStatusText,
                                  onLogin: (email, password, rememberMe) {
                                    _handleLoginWithLocation(
                                      email: email,
                                      password: password,
                                      rememberMe: rememberMe,
                                    );
                                  },
                                  onForgotPasswordTap: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(
                                        child: BlocProvider.value(
                                          value: context.read<AuthBloc>(),
                                          child: const ForgotPasswordPage(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Alternatif Login via Native Google Sign-In (modal Android Play Services)
                                SocialLoginButtons(
                                  isLoading: isLoading,
                                  onGooglePressed: _handleGoogleLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Footer: Tautan Pendaftaran
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Belum punya akun SatSet? ',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _userInitiatedLogin = false;
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(
                                        child: BlocProvider.value(
                                          value: context.read<AuthBloc>(),
                                          child: const RegisterPage(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Daftar Sekarang',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: InkWell(
                              onTap: () {
                                _userInitiatedLogin = false;
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    child: BlocProvider.value(
                                      value: context.read<AuthBloc>(),
                                      child: const CourierRegisterPage(),
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.delivery_dining_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Gabung Menjadi Mitra Kurir SatSet',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToRoleDestination(BuildContext context, User user) {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(user);
    }
    // Jika tidak ditangani oleh callback root, navigasikan langsung sesuai id_users_role
    if (Navigator.of(context).canPop() || widget.onLoginSuccess == null) {
      if (user.idUsersRole == 2 || user.role == 'courier') {
        // id_users_role = 2 -> Halaman Utama Kurir lengkap dengan Bilah Navigasi Bawah
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                CourierMainNavigationPage(user: user, token: user.token),
          ),
          (route) => false,
        );
      } else {
        // id_users_role = 3 -> Halaman Dashboard Pelanggan (DashboardPage)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DashboardPage(token: user.token, user: user),
          ),
          (route) => false,
        );
      }
    }
  }


  /// Memeriksa izin akses lokasi & GPS sebelum memproses login SatSet
  Future<void> _handleLoginWithLocation({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (_isCheckingLocation) return;

    setState(() {
      _isCheckingLocation = true;
      _loadingStatusText = 'Memeriksa GPS...';
    });

    try {
      // 1. Periksa apakah layanan GPS aktif di perangkat
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _loadingStatusText = null;
          });
          CustomDialog.showWarning(
            context: context,
            title: 'GPS Tidak Aktif',
            message: 'Layanan lokasi (GPS) belum diaktifkan. Mohon aktifkan GPS perangkat Anda agar dapat masuk ke akun SatSet.',
            confirmText: 'Buka Pengaturan',
            cancelText: 'Batal',
            onConfirm: () async {
              await Geolocator.openLocationSettings();
            },
          );
        }
        return;
      }

      // 2. Periksa status izin akses lokasi
      setState(() {
        _loadingStatusText = 'Memeriksa izin lokasi...';
      });

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isCheckingLocation = false;
              _loadingStatusText = null;
            });
            CustomDialog.showWarning(
              context: context,
              title: 'Izin Lokasi Diperlukan',
              message: 'Aplikasi SatSet membutuhkan izin akses lokasi Anda saat masuk untuk verifikasi lokasi pengguna.',
              confirmText: 'Mengerti',
              cancelText: null,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _loadingStatusText = null;
          });
          CustomDialog.showWarning(
            context: context,
            title: 'Izin Lokasi Ditolak Permanen',
            message: 'Izin akses lokasi ditolak permanen di perangkat ini. Silakan aktifkan izin lokasi di menu Pengaturan Aplikasi.',
            confirmText: 'Buka Pengaturan',
            cancelText: 'Batal',
            onConfirm: () async {
              await Geolocator.openAppSettings();
            },
          );
        }
        return;
      }

      // 3. Izin lokasi diberikan, ambil koordinat lokasi terkini (GPS)
      setState(() {
        _loadingStatusText = 'Mendeteksi lokasi saat ini...';
      });

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        // Fallback ke posisi cache terakhir jika timeout
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _isCheckingLocation = false;
        _loadingStatusText = null;
        _userInitiatedLogin = true;
      });

      // Notifikasi ringkas bahwa lokasi login terdeteksi
      if (position != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokasi login: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 4. Submit login dengan koordinat lokasi terkini
      context.read<AuthBloc>().add(
        AuthLoginSubmitted(
          email: email,
          password: password,
          rememberMe: rememberMe,
          latitude: position?.latitude,
          longitude: position?.longitude,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _loadingStatusText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa lokasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Masuk dengan Google: Membuka modal native Android Google Play Services tanpa browser Chrome
  Future<void> _handleGoogleLogin() async {
    if (_isCheckingLocation) return;
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _userInitiatedLogin = true;
    });
    context.read<AuthBloc>().add(const AuthGoogleLoginSubmitted());
  }
}
