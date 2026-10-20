import 'package:equatable/equatable.dart';
import '../../domain/entities/navigation_item.dart';

class NavigationState extends Equatable {
  final NavigationTab currentTab;
  final String? message;

  const NavigationState({
    this.currentTab = NavigationTab.home,
    this.message,
  });

  NavigationState copyWith({
    NavigationTab? currentTab,
    String? message,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        currentTab,
        message,
      ];
}
