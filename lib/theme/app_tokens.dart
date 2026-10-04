import 'package:flutter/material.dart';

/// Centralized Material 3 Design Tokens for SafeKey
/// Following strict Material Design 3 Expressive guidelines.
abstract class AppTokens {
  // Spacing Tokens (8dp grid system)
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space36 = 36.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;

  // Insets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: space16, vertical: space12);
  static const EdgeInsets cardPadding = EdgeInsets.all(space16);
  static const EdgeInsets dialogPadding = EdgeInsets.all(space24);
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(space24, space8, space24, space24);

  // Shape Tokens (Border Radius)
  static const double radiusNone = 0.0;
  static const double radiusExtraSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double radiusExpressive = 28.0;
  static const double radiusFull = 999.0;

  // Semantic Corner Radii
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusExtraLarge = BorderRadius.all(Radius.circular(radiusExtraLarge));
  static const BorderRadius borderRadiusExpressive = BorderRadius.all(Radius.circular(radiusExpressive));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // Elevation Tokens
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 6.0;
  static const double elevation5 = 8.0;

  // Icon Sizes
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  static const double iconSizeHero = 80.0;
}
