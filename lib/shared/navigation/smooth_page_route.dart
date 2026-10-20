import 'package:flutter/material.dart';

/// Builder transisi halaman yang sangat ringan (smooth fade)
/// tanpa animasi gerak, zoom, atau slide yang membebani GPU/CPU perangkat.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Hanya fade halus tanpa translasi/skala yang membebani rendering perangkat
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }
}

/// Route kustom yang dirancang agar perpindahan halaman terasa instan dan smooth,
/// tanpa animasi berat (zoom / slide) yang membuat aplikasi terasa berat/lag.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({
    required this.child,
    super.settings,
    Duration duration = const Duration(milliseconds: 150),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}
