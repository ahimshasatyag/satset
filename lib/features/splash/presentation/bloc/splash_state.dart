import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings_entity.dart';

/// Basis class untuk seluruh state di SplashBloc
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum ada event yang dieksekusi
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// State saat menampilkan Splash Screen logo animasi sambil membaca konfigurasi awal
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// State saat menampilkan halaman Onboarding (slider pengenalan fitur mirip desain)
class SplashOnboardingState extends SplashState {
  final int currentPage;
  final int totalPages;
  final AppSettingsEntity settings;

  const SplashOnboardingState({
    required this.currentPage,
    this.totalPages = 3,
    required this.settings,
  });

  bool get isLastPage => currentPage == totalPages - 1;

  SplashOnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    AppSettingsEntity? settings,
  }) {
    return SplashOnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, settings];
}

/// State ketika pengguna sudah login sebelumnya (arahkan ke Dashboard)
class SplashAuthenticated extends SplashState {
  final AppSettingsEntity settings;

  const SplashAuthenticated(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// State ketika pengguna belum login (arahkan ke Login / Beranda)
class SplashUnauthenticated extends SplashState {
  final AppSettingsEntity settings;

  const SplashUnauthenticated(this.settings);

  @override
  List<Object?> get props => [settings];
}
