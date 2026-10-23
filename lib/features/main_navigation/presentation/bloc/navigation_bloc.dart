import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/main_navigation_repository_impl.dart';
import '../../domain/entities/navigation_item.dart';
import '../../domain/repositories/main_navigation_repository.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final MainNavigationRepository repository;

  StreamSubscription<int>? _activeTasksSubscription;
  StreamSubscription<int>? _notificationsSubscription;

  NavigationBloc({MainNavigationRepository? repository})
      : repository = repository ?? MainNavigationRepositoryImpl(),
        super(const NavigationState()) {
    on<NavigationTabChanged>(_onTabChanged);
    on<CourierNavigationTabChanged>(_onCourierTabChanged);
    on<NavigationCourierAuthChecked>(_onCourierAuthChecked);
    on<NavigationCourierSubscribed>(_onCourierSubscribed);
    on<NavigationActiveTasksCountUpdated>(_onActiveTasksCountUpdated);
    on<NavigationUnreadNotificationsCountUpdated>(
        _onUnreadNotificationsCountUpdated);
    on<NavigationCourierRefreshRequested>(_onCourierRefreshRequested);
    on<NavigationLogoutRequested>(_onLogoutRequested);
  }

  void _onTabChanged(
    NavigationTabChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(currentTab: event.tab));
    repository.saveLastSelectedTab(event.tab.index).ignore();
  }

  void _onCourierTabChanged(
    CourierNavigationTabChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(currentCourierTab: event.tab));
    repository.saveCourierLastSelectedTab(event.tab.index).ignore();
  }

  Future<void> _onCourierAuthChecked(
    NavigationCourierAuthChecked event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final isAuthorized = await repository.verifyCourierAccess(
        userId: event.userId,
        email: event.email,
      );

      if (!isAuthorized) {
        emit(state.copyWith(
          isLoading: false,
          isCourierAuthorized: false,
          errorMessage:
              'Akses ditolak: Akun ini tidak terdaftar sebagai kurir dengan id_users_role=2 pada tabel m_employee.',
        ));
        return;
      }

      // Ambil index tab kurir yang terakhir dibuka jika ada
      final lastTabIndex = await repository.getCourierLastSelectedTab();
      final lastTab = lastTabIndex >= 0 &&
              lastTabIndex < CourierNavigationTab.values.length
          ? CourierNavigationTab.values[lastTabIndex]
          : CourierNavigationTab.tasks;

      // Ambil data awal jumlah tugas aktif dan notifikasi
      final activeTasks = await repository.getActiveTasksCount(event.userId);
      final unreadNotifs =
          await repository.getUnreadNotificationsCount(event.userId);

      emit(state.copyWith(
        isLoading: false,
        isCourierAuthorized: true,
        currentCourierTab: lastTab,
        activeTasksCount: activeTasks,
        unreadNotificationsCount: unreadNotifs,
      ));

      // Daftarkan listener realtime
      add(NavigationCourierSubscribed(
        courierId: event.userId,
        userId: event.userId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memverifikasi status akun kurir: $e',
      ));
    }
  }

  Future<void> _onCourierSubscribed(
    NavigationCourierSubscribed event,
    Emitter<NavigationState> emit,
  ) async {
    await _activeTasksSubscription?.cancel();
    await _notificationsSubscription?.cancel();

    _activeTasksSubscription = repository
        .streamActiveTasksCount(event.courierId)
        .listen((count) {
      add(NavigationActiveTasksCountUpdated(count));
    });

    _notificationsSubscription = repository
        .streamUnreadNotificationsCount(event.userId)
        .listen((count) {
      add(NavigationUnreadNotificationsCountUpdated(count));
    });
  }

  void _onActiveTasksCountUpdated(
    NavigationActiveTasksCountUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(activeTasksCount: event.count));
  }

  void _onUnreadNotificationsCountUpdated(
    NavigationUnreadNotificationsCountUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(unreadNotificationsCount: event.count));
  }

  Future<void> _onCourierRefreshRequested(
    NavigationCourierRefreshRequested event,
    Emitter<NavigationState> emit,
  ) async {
    try {
      final activeTasks = await repository.getActiveTasksCount(event.courierId);
      final unreadNotifs =
          await repository.getUnreadNotificationsCount(event.courierId);

      emit(state.copyWith(
        activeTasksCount: activeTasks,
        unreadNotificationsCount: unreadNotifs,
        message: 'Data tugas kurir berhasil diperbarui',
      ));
    } catch (_) {}
  }

  Future<void> _onLogoutRequested(
    NavigationLogoutRequested event,
    Emitter<NavigationState> emit,
  ) async {
    await _activeTasksSubscription?.cancel();
    await _notificationsSubscription?.cancel();
    await repository.logout();

    emit(const NavigationState(
      currentTab: NavigationTab.home,
      currentCourierTab: CourierNavigationTab.tasks,
      isCourierAuthorized: false,
      isSessionExpired: true,
    ));
  }

  @override
  Future<void> close() async {
    await _activeTasksSubscription?.cancel();
    await _notificationsSubscription?.cancel();
    return super.close();
  }
}
