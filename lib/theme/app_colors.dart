import 'package:flutter/material.dart';

/// Semantic Material 3 Color Palettes and Status Accents for SafeKey.
abstract class AppColors {
  // Brand Tonal Seeds
  static const Color primaryLight = Color(0xFF1D4ED8); // Deep Cobalt
  static const Color primaryDark = Color(0xFF60A5FA);  // Electric Sky Blue

  static const Color secondaryLight = Color(0xFF0369A1); // Cyan Marine
  static const Color secondaryDark = Color(0xFF38BDF8);  // Soft Neon Cyan

  static const Color tertiaryLight = Color(0xFF6D28D9); // Violet Purple
  static const Color tertiaryDark = Color(0xFFA78BFA);  // Pastel Lavender

  // Totp Urgency Status Colors
  static const Color totpSafe = Color(0xFF10B981);      // Emerald Green (> 10s)
  static const Color totpWarning = Color(0xFFF59E0B);   // Warm Amber (5s - 10s)
  static const Color totpCritical = Color(0xFFEF4444);  // Coral Red (< 5s)

  // Light Mode Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1D4ED8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),

    secondary: Color(0xFF0284C7),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondaryContainer: Color(0xFF0C4A6E),

    tertiary: Color(0xFF7C3AED),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEDE9FE),
    onTertiaryContainer: Color(0xFF4C1D95),

    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),

    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    surfaceDim: Color(0xFFE2E8F0),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFE8EEF5),
    surfaceContainerHigh: Color(0xFFDFE6F0),
    surfaceContainerHighest: Color(0xFFD3DDEB),

    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF1F5F9),
    inversePrimary: Color(0xFF93C5FD),
    surfaceTint: Color(0xFF1D4ED8),
  );

  // Dark Mode Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),

    secondary: Color(0xFF38BDF8),
    onSecondary: Color(0xFF082F49),
    secondaryContainer: Color(0xFF0C4A6E),
    onSecondaryContainer: Color(0xFFBAE6FD),

    tertiary: Color(0xFFA78BFA),
    onTertiary: Color(0xFF2E1065),
    tertiaryContainer: Color(0xFF4C1D95),
    onTertiaryContainer: Color(0xFFDDD6FE),

    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),

    surface: Color(0xFF0B0F19),
    onSurface: Color(0xFFF1F5F9),
    surfaceDim: Color(0xFF070A12),
    surfaceBright: Color(0xFF1E2638),
    surfaceContainerLowest: Color(0xFF06080E),
    surfaceContainerLow: Color(0xFF101726),
    surfaceContainer: Color(0xFF161F33),
    surfaceContainerHigh: Color(0xFF1C2740),
    surfaceContainerHighest: Color(0xFF243252),

    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF1D4ED8),
    surfaceTint: Color(0xFF60A5FA),
  );
}
