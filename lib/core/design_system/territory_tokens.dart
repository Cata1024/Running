import 'package:flutter/material.dart';

class TerritoryTokens {
  // Blur levels (selective, not global)
  static const double blurNone = 0;
  static const double blurSubtle = 4;
  static const double blurMedium = 8;
  static const double blurStrong = 16;

  // Opacity levels (leaner than classic glass)
  static const double opacityGhost = 0.03;
  static const double opacitySubtle = 0.08;
  static const double opacityMedium = 0.15;
  static const double opacityStrong = 0.25;

  // Border widths
  static const double borderNone = 0;
  static const double borderHairline = 0.5;
  static const double borderThin = 1.0;

  // Spacing scale
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // Border radius scale
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusPill = 9999;

  // Animation durations
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Shadow recipes (subtle multi-layer depth)
  static List<BoxShadow> shadowSubtle(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMedium(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
