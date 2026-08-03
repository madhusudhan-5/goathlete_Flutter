import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class GoAthleteTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: GoAthleteColors.primary,
        onPrimary: GoAthleteColors.onPrimary,
        primaryContainer: GoAthleteColors.primaryContainer,
        onPrimaryContainer: GoAthleteColors.onPrimaryContainer,
        secondary: GoAthleteColors.secondary,
        onSecondary: GoAthleteColors.onSecondary,
        secondaryContainer: GoAthleteColors.secondaryContainer,
        onSecondaryContainer: GoAthleteColors.onSecondaryContainer,
        tertiary: GoAthleteColors.tertiary,
        onTertiary: GoAthleteColors.onTertiary,
        tertiaryContainer: GoAthleteColors.tertiaryContainer,
        onTertiaryContainer: GoAthleteColors.onTertiaryContainer,
        error: GoAthleteColors.error,
        onError: GoAthleteColors.onError,
        errorContainer: GoAthleteColors.errorContainer,
        onErrorContainer: GoAthleteColors.onErrorContainer,
        background: GoAthleteColors.background,
        onBackground: GoAthleteColors.onBackground,
        surface: GoAthleteColors.surface,
        onSurface: GoAthleteColors.onSurface,
        surfaceVariant: GoAthleteColors.surfaceVariant,
        onSurfaceVariant: GoAthleteColors.onSurfaceVariant,
        outline: GoAthleteColors.outline,
        outlineVariant: GoAthleteColors.outlineVariant,
        inverseSurface: GoAthleteColors.inverseSurface,
        onInverseSurface: GoAthleteColors.inverseOnSurface,
        inversePrimary: GoAthleteColors.inversePrimary,
      ),
      textTheme: GoAthleteTypography.getTextTheme(),
      cardTheme: CardThemeData(
        color: GoAthleteColors.surfaceContainerLowest,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoAthleteColors.athleticOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoAthleteTypography.getTextTheme().labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoAthleteColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GoAthleteColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GoAthleteColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GoAthleteColors.athleticOrange),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: GoAthleteColors.inversePrimary,
        onPrimary: GoAthleteColors.onPrimaryContainer,
        primaryContainer: GoAthleteColors.primary,
        onPrimaryContainer: GoAthleteColors.onPrimary,
        background: GoAthleteColors.deepestMidnight,
        onBackground: Colors.white,
        surface: GoAthleteColors.deepNavy,
        onSurface: Colors.white,
        surfaceVariant: GoAthleteColors.inverseSurface,
        onSurfaceVariant: GoAthleteColors.inverseOnSurface,
        outline: GoAthleteColors.outlineVariant,
        outlineVariant: GoAthleteColors.outline,
      ),
      textTheme: GoAthleteTypography.getTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: GoAthleteColors.inverseSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoAthleteColors.athleticOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoAthleteTypography.getTextTheme().labelMedium,
        ),
      ),
    );
  }
}
