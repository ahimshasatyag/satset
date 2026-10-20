import 'package:equatable/equatable.dart';
import '../../domain/entities/navigation_item.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Pengguna berpindah menu tab pada bottom navigation bar
class NavigationTabChanged extends NavigationEvent {
  final NavigationTab tab;

  const NavigationTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}
