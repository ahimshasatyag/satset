import 'package:equatable/equatable.dart';

/// Basis class untuk seluruh event di SplashBloc
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat Splash Screen pertama kali dibuka
class SplashInitEvent extends SplashEvent {
  const SplashInitEvent();
}

/// Event ketika halaman onboarding berubah (geser atau tekan Next)
class SplashPageChangedEvent extends SplashEvent {
  final int pageIndex;

  const SplashPageChangedEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

/// Event saat pengguna menekan "Skip" atau "Let's Go" untuk menyelesaikan onboarding
class SplashFinishOnboardingEvent extends SplashEvent {
  const SplashFinishOnboardingEvent();
}
