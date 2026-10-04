import 'package:flutter/material.dart';

/// Semantic colors for SafeKey (Success/Safe, Warning/Expiring, Critical/Error).
/// Integrates with Material 3 dynamic color through tonal harmony.
extension ColorSchemeSemanticExt on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Semantic Success / TOTP Fresh State (> 10s remaining)
  Color get success {
    return _isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  }

  /// On-color for Success
  Color get onSuccess {
    return _isDark ? const Color(0xFF064E3B) : const Color(0xFFFFFFFF);
  }

  /// Success container background
  Color get successContainer {
    return _isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.6)
        : const Color(0xFFD1FAE5);
  }

  /// On-color for Success Container
  Color get onSuccessContainer {
    return _isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
  }

  /// Semantic Warning / TOTP Expiring State (5s - 10s remaining)
  Color get warning {
    return _isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  }

  /// On-color for Warning
  Color get onWarning {
    return _isDark ? const Color(0xFF78350F) : const Color(0xFFFFFFFF);
  }

  /// Warning container background
  Color get warningContainer {
    return _isDark
        ? const Color(0xFF78350F).withValues(alpha: 0.6)
        : const Color(0xFFFEF3C7);
  }

  /// On-color for Warning Container
  Color get onWarningContainer {
    return _isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
  }

  /// Semantic Critical / Urgent State (< 5s remaining)
  Color get critical => error;

  /// On-color for Critical
  Color get onCritical => onError;

  /// Critical container
  Color get criticalContainer => errorContainer;

  /// On-color for Critical Container
  Color get onCriticalContainer => onErrorContainer;
}
