import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/splash_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_app_settings_usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC untuk mengelola alur logika Splash Screen dan Onboarding
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final GetAppSettingsUseCase getAppSettingsUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final SplashRepository repository;

  SplashBloc({
    required this.getAppSettingsUseCase,
    required this.checkAuthStatusUseCase,
    required this.repository,
  }) : super(const SplashInitial()) {
    on<SplashInitEvent>(_onSplashInit);
    on<SplashPageChangedEvent>(_onPageChanged);
    on<SplashFinishOnboardingEvent>(_onFinishOnboarding);
  }

  Future<void> _onSplashInit(
    SplashInitEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    // Beri jeda tampilan logo splash screen (1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    final settings = await getAppSettingsUseCase();
    final isAuthenticated = await checkAuthStatusUseCase();

    final updatedSettings = settings.copyWith(isAuthenticated: isAuthenticated);

    // Jika pengguna baru pertama kali membuka app, tampilkan onboarding slider
    if (updatedSettings.isFirstTime) {
      emit(SplashOnboardingState(
        currentPage: 0,
        totalPages: 3,
        settings: updatedSettings,
      ));
    } else if (isAuthenticated) {
      emit(SplashAuthenticated(updatedSettings));
    } else {
      emit(SplashUnauthenticated(updatedSettings));
    }
  }

  void _onPageChanged(
    SplashPageChangedEvent event,
    Emitter<SplashState> emit,
  ) {
    if (state is SplashOnboardingState) {
      final current = state as SplashOnboardingState;
      emit(current.copyWith(currentPage: event.pageIndex));
    }
  }

  Future<void> _onFinishOnboarding(
    SplashFinishOnboardingEvent event,
    Emitter<SplashState> emit,
  ) async {
    await repository.setFirstTime(false);

    AppSettingsEntity currentSettings = const AppSettingsEntity.initial();
    if (state is SplashOnboardingState) {
      currentSettings = (state as SplashOnboardingState).settings;
    }

    if (currentSettings.isAuthenticated) {
      emit(SplashAuthenticated(currentSettings.copyWith(isFirstTime: false)));
    } else {
      emit(SplashUnauthenticated(currentSettings.copyWith(isFirstTime: false)));
    }
  }
}
