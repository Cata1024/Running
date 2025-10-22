import 'package:flutter/material.dart';
import 'territory_tokens.dart';

class TerritoryTheme {
  static ThemeData light([ColorScheme? dynamicScheme]) {
    final ColorScheme baseScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        );

    final ColorScheme territoryScheme = baseScheme.copyWith(
      primary: _adjustSaturation(baseScheme.primary, 1.15),
      tertiary: _adjustSaturation(baseScheme.tertiary, 1.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: territoryScheme,
      textTheme: _buildTextTheme(territoryScheme),
      elevatedButtonTheme: _buildButtonTheme(territoryScheme),
      inputDecorationTheme: _buildInputTheme(territoryScheme),
      scaffoldBackgroundColor: territoryScheme.surface,
    );
  }

  static ThemeData dark([ColorScheme? dynamicScheme]) {
    final ColorScheme baseScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        );

    final ColorScheme territoryScheme = baseScheme.copyWith(
      primary: _adjustSaturation(baseScheme.primary, 1.15),
      tertiary: _adjustSaturation(baseScheme.tertiary, 1.1),
      surface: const Color(0xFF0A0A0A),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: territoryScheme,
      textTheme: _buildTextTheme(territoryScheme),
      elevatedButtonTheme: _buildButtonTheme(territoryScheme),
      inputDecorationTheme: _buildInputTheme(territoryScheme),
      scaffoldBackgroundColor: territoryScheme.surface,
    );
  }

  static Color _adjustSaturation(Color color, double factor) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * factor).clamp(0.0, 1.0))
        .toColor();
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),
    );
  }

  static ElevatedButtonThemeData _buildButtonTheme(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.2),
          width: TerritoryTokens.borderThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        borderSide: BorderSide(
          color: scheme.primary,
          width: TerritoryTokens.borderThin,
        ),
      ),
    );
  }
}
