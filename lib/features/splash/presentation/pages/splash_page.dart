import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/features/splash/data/datasources/splash_local_datasource.dart';
import 'package:satset/features/splash/data/repositories/splash_repository_impl.dart';
import 'package:satset/features/splash/domain/usecases/check_auth_status_usecase.dart';
import 'package:satset/features/splash/domain/usecases/get_app_settings_usecase.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import '../widgets/splash_logo.dart';
import '../widgets/splash_version.dart';

/// Data model untuk konten tiap slide Onboarding
class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

/// Halaman Splash Screen & Onboarding dengan desain selaras tema SatSet,
/// arsitektur BLoC, animasi dot indikator, dan komponen tombol dari shared widgets.
class SplashPage extends StatelessWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToLogin;

  const SplashPage({super.key, this.onNavigateToHome, this.onNavigateToLogin});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi dependensi lokal jika tidak menggunakan service locator
    final localDataSource = SplashLocalDataSourceImpl();
    final repository = SplashRepositoryImpl(localDataSource: localDataSource);
    final getAppSettingsUseCase = GetAppSettingsUseCase(repository);
    final checkAuthStatusUseCase = CheckAuthStatusUseCase(repository);

    return BlocProvider(
      create: (context) => SplashBloc(
        getAppSettingsUseCase: getAppSettingsUseCase,
        checkAuthStatusUseCase: checkAuthStatusUseCase,
        repository: repository,
      )..add(const SplashInitEvent()),
      child: SplashView(
        key: UniqueKey(),
        onNavigateToHome: onNavigateToHome,
        onNavigateToLogin: onNavigateToLogin,
      ),
    );
  }
}

class SplashView extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToLogin;

  const SplashView({super.key, this.onNavigateToHome, this.onNavigateToLogin});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final PageController _pageController;

  final List<OnboardingItem> _onboardingItems = const [
    OnboardingItem(
      title: 'Delivery to your home',
      description:
          'Layanan antar kilat langsung ke depan pintu rumah Anda dengan kurir terpercaya.',
      imagePath: 'assets/images/Splash1.png',
    ),
    OnboardingItem(
      title: 'Prepared by experts',
      description:
          'Pantau pergerakan paket secara real-time dan akurat langsung dari ponsel Anda.',
      imagePath: 'assets/images/Splash2.png',
    ),
    OnboardingItem(
      title: 'Enjoy with everyone',
      description:
          'Sat-Set sampai, hati pun santai. Nikmati kemudahan kirim barang tanpa rasa cemas.',
      imagePath: 'assets/images/Splash3.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  bool _hasPrecachedBackground = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecachedBackground) {
      _hasPrecachedBackground = true;
      // Precache background Login saat pengguna berada di splash/onboarding agar background login tidak sempat hilang/berkedip
      precacheImage(const AssetImage('assets/images/Background.png'), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    context.read<SplashBloc>().add(SplashPageChangedEvent(index));
  }

  void _onNextPressed(int currentPage) {
    if (currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<SplashBloc>().add(const SplashFinishOnboardingEvent());
    }
  }

  void _onSkipPressed() {
    context.read<SplashBloc>().add(const SplashFinishOnboardingEvent());
  }

  Color _getBlobColor(int index, bool isDark) {
    if (isDark) {
      switch (index) {
        case 0:
          return AppColors.primary900.withValues(alpha: 0.35);
        case 1:
          return AppColors.secondary900.withValues(alpha: 0.35);
        case 2:
        default:
          return AppColors.tertiary800.withValues(alpha: 0.35);
      }
    } else {
      switch (index) {
        case 0:
          return AppColors.primary50;
        case 1:
          return AppColors.secondary50;
        case 2:
        default:
          return AppColors.tertiary50;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background motif dari BackgroundSplash.jpg untuk seluruh splash screen & onboarding
          Positioned.fill(
            child: Image.asset(
              'assets/images/BackgroundSplash.jpg',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // Lapisan overlay halus untuk mode gelap agar teks & ilustrasi tetap kontras optimal
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          // Konten Splash Screen (Logo & Loading maupun Slider Onboarding)
          BlocConsumer<SplashBloc, SplashState>(
            listener: (context, state) {
              if (state is SplashAuthenticated) {
                if (widget.onNavigateToHome != null) {
                  widget.onNavigateToHome!();
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              } else if (state is SplashUnauthenticated) {
                if (widget.onNavigateToLogin != null) {
                  widget.onNavigateToLogin!();
                } else {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            builder: (context, state) {
              if (state is SplashInitial || state is SplashLoading) {
                return _buildSplashLoadingScreen(context, isDark);
              }

              if (state is SplashOnboardingState) {
                return _buildOnboardingScreen(
                    context, state.currentPage, isDark);
              }

              // State selesai
              return _buildSplashLoadingScreen(context, isDark);
            },
          ),
        ],
      ),
    );
  }

  /// Tampilan Splash Logo awal saat aplikasi pertama kali memuat konfigurasi
  Widget _buildSplashLoadingScreen(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Logo di tengah
        const Center(child: SplashLogo(size: 210, showTagline: true)),

        // Indikator loading kustom dari shared widgets
        const Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: CustomLoading(
              size: 28,
              color: AppColors.primary,
            ),
          ),
        ),

        // Versi di bagian bawah
        const Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(child: SplashVersion(version: '1.0.0')),
        ),
      ],
    );
  }

  /// Tampilan Onboarding Slider selaras tema brand SatSet
  Widget _buildOnboardingScreen(
    BuildContext context,
    int currentPage,
    bool isDark,
  ) {
    final isLastPage = currentPage == _onboardingItems.length - 1;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Header: Judul Brand SatSet Express
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SATSET',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Express',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PageView untuk 3 Slide
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _onboardingItems.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = _onboardingItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Organic Blob Backdrop + Ilustrasi
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Organic blob shape dengan warna tema SatSet
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: _getBlobColor(index, isDark),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(150),
                                    topRight: const Radius.circular(130),
                                    bottomLeft: const Radius.circular(140),
                                    bottomRight: Radius.circular(
                                      index == 1 ? 160 : 120,
                                    ),
                                  ),
                                ),
                              ),

                              // Ilustrasi
                              Image.asset(
                                item.imagePath,
                                width: 260,
                                height: 260,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dot Indicators
          _buildPageIndicators(currentPage, isDark),

          const SizedBox(height: 32),

          // Bottom Navigation Buttons menggunakan CustomButton dari shared widgets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Skip (CustomButton ghost)
                if (!isLastPage)
                  CustomButton.ghost(
                    text: 'Skip',
                    onPressed: _onSkipPressed,
                    isFullWidth: false,
                    borderRadius: BorderRadius.circular(24),
                    size: ButtonSize.medium,
                  )
                else
                  const SizedBox(width: 80),

                // Tombol Next / Let's Go (CustomButton gradient brand)
                CustomButton.gradient(
                  text: isLastPage ? "Let's Go" : 'Next',
                  onPressed: () => _onNextPressed(currentPage),
                  isFullWidth: false,
                  borderRadius: BorderRadius.circular(24),
                  size: ButtonSize.medium,
                  suffixIcon: Icon(
                    isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Indikator halaman: Titik aktif berbentuk pill gradient SatSet
  Widget _buildPageIndicators(int activeIndex, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_onboardingItems.length, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive
                ? null
                : (isDark
                    ? AppColors.borderDark
                    : AppColors.primary100.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
