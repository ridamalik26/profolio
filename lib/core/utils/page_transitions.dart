import 'package:flutter/material.dart';

/// Fade + gentle upward slide, used in place of the platform-default route
/// for the app's main navigation actions.
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  SlideFadePageRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Future<T?> pushSlideFade<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SlideFadePageRoute<T>(builder: (_) => page));
}
