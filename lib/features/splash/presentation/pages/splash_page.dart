import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/features/splash/data/datasources/splash_local_datasource.dart';
import 'package:satset/features/splash/data/repositories/splash_repository_impl.dart';
import 'package:satset/features/splash/domain/usecases/check_auth_status_usecase.dart';
import 'package:satset/features/splash/domain/usecases/get_app_settings_usecase.dart';
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

/// Halaman Splash Screen & Onboarding dengan desain selaras screenshot referensi,
/// arsitektur BLoC, animasi dot indikator, dan transisi mulus.
class SplashPage extends StatelessWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToLogin;

  const SplashPage({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToLogin,
  });

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
        onNavigateToHome: onNavigateToHome,
        onNavigateToLogin: onNavigateToLogin,
      ),
    );
  }
}

class SplashView extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToLogin;

  const SplashView({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToLogin,
  });

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
    _pageController = PageController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashAuthenticated) {
            if (widget.onNavigateToHome != null) {
              widget.onNavigateToHome!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigasi ke Beranda (Sudah Login)')),
              );
            }
          } else if (state is SplashUnauthenticated) {
            if (widget.onNavigateToLogin != null) {
              widget.onNavigateToLogin!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigasi ke Login / Registrasi')),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is SplashInitial || state is SplashLoading) {
            return _buildSplashLoadingScreen();
          }

          if (state is SplashOnboardingState) {
            return _buildOnboardingScreen(state.currentPage);
          }

          // State selesai
          return _buildSplashLoadingScreen();
        },
      ),
    );
  }

  /// Tampilan Splash Logo awal saat aplikasi pertama kali memuat konfigurasi
  Widget _buildSplashLoadingScreen() {
    return Stack(
      children: [
        // Background motif lembut
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Image.asset(
              'assets/images/BackgroundSplash.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Logo di tengah
        const Center(
          child: SplashLogo(
            size: 210,
            showTagline: true,
          ),
        ),

        // Versi di bagian bawah
        const Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: SplashVersion(version: '1.0.0'),
          ),
        ),
      ],
    );
  }

  /// Tampilan Onboarding Slider persis seperti referensi desain (3 slide)
  Widget _buildOnboardingScreen(int currentPage) {
    final isLastPage = currentPage == _onboardingItems.length - 1;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Header: Judul Brand ("Food Express" di referensi -> "SatSet Express")
          const Center(
            child: Text(
              'Food Express',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A3A),
                letterSpacing: 0.2,
              ),
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
                      // Organic Blob Backdrop + Ilustrasi 3D
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Organic blob shape (soft pastel mint)
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6EDE6),
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

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A3A),
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
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: const Color(0xFF1E3A3A).withValues(alpha: 0.7),
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

          // Dot Indicators (Pill memanjang untuk active, titik untuk inactive)
          _buildPageIndicators(currentPage),

          const SizedBox(height: 32),

          // Bottom Navigation Buttons (Skip di kiri, Next / Let's Go di kanan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Skip (Pill mint lembut)
                if (!isLastPage)
                  InkWell(
                    onTap: _onSkipPressed,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6EDE6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF1E3A3A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),

                // Tombol Next / Let's Go (Pill gelap elegan)
                InkWell(
                  onTap: () => _onNextPressed(currentPage),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLastPage ? 36 : 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A3A),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A3A).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isLastPage ? "Let's Go" : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
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

  /// Indikator halaman: Titik aktif berbentuk pill oval memanjang
  Widget _buildPageIndicators(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingItems.length,
        (index) {
          final isActive = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1E3A3A)
                  : const Color(0xFF1E3A3A).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}
