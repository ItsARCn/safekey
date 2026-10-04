import 'package:flutter/material.dart';

/// Centralized Material 3 Motion System for SafeKey.
/// Complies with Google Material Motion guidelines:
/// - Expressive spring and bezier easings
/// - Hierarchical durations (short, medium, long, extraLong)
/// - Shared-axis, Container transform, and Fade-through page transition helpers.
abstract class AppMotion {
  // Durations
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);

  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);
  static const Duration extraLong3 = Duration(milliseconds: 900);
  static const Duration extraLong4 = Duration(milliseconds: 1000);

  // Material 3 Easing Curves
  /// Standard easing for simple component state changes
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard decelerate for incoming elements
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);

  /// Standard accelerate for elements leaving the viewport
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  /// Emphasized easing for rich, expressive movements (page transitions, container expansion)
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Emphasized decelerate: dramatic slowdown towards arrival
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized accelerate: snappy departure
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Spring physics curve for tactile tactile micro-interactions
  static const Curve spring = Curves.easeOutBack;

  /// Smooth responsive curve for cards and micro-gestures
  static const Curve responsive = Curves.easeOutCubic;

  /// Custom Material 3 shared-axis page transition
  static Widget sharedAxisTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    AxisDirection direction = AxisDirection.up,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: emphasizedDecelerate,
      reverseCurve: emphasizedAccelerate,
    );

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: emphasizedAccelerate,
      reverseCurve: emphasizedDecelerate,
    );

    Offset beginOffset;
    switch (direction) {
      case AxisDirection.up:
        beginOffset = const Offset(0.0, 0.06);
        break;
      case AxisDirection.down:
        beginOffset = const Offset(0.0, -0.06);
        break;
      case AxisDirection.left:
        beginOffset = const Offset(0.06, 0.0);
        break;
      case AxisDirection.right:
        beginOffset = const Offset(-0.06, 0.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: -beginOffset * 0.5,
      ).animate(secondaryCurved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.85).animate(secondaryCurved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            )),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Fade through transition for lateral navigation destinations
  static Widget fadeThroughTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final primaryFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.35, 1.0, curve: standardDecelerate),
    );

    final primaryScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: emphasizedDecelerate),
    );

    final secondaryFade = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.35, curve: standardAccelerate),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryFade),
      child: FadeTransition(
        opacity: primaryFade,
        child: ScaleTransition(
          scale: primaryScale,
          child: child,
        ),
      ),
    );
  }
}
