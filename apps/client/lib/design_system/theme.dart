import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static final light = _build(AppColors.light, Brightness.light);
  static final dark = _build(AppColors.dark, Brightness.dark);
  static ThemeData _build(AppColors colors, Brightness brightness) => ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.bodyFamily,
    visualDensity: VisualDensity.standard,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          primaryContainer: colors.primarySoft,
          onPrimaryContainer: colors.text,
          surface: colors.surface,
          onSurface: colors.text,
          onSurfaceVariant: colors.muted,
          surfaceContainerHighest: colors.surface,
          error: colors.error,
          outline: colors.border,
          outlineVariant: colors.border,
        ),
    textTheme: AppTypography.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    ),
    dividerColor: colors.border,
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const StadiumBorder(),
            textStyle: AppTypography.textTheme.labelLarge,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? BorderSide(color: colors.text, width: 2)
                  : BorderSide.none,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const StadiumBorder(),
            side: BorderSide(color: colors.border),
            foregroundColor: colors.text,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? colors.primary
                    : colors.border,
                width: states.contains(WidgetState.focused) ? 2 : 1,
              ),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: brightness == Brightness.dark
            ? const Color(0xFFB89BFF)
            : colors.primary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.background,
      indicatorColor: colors.primarySoft,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTypography.bodyFamily,
          color: colors.text,
          fontSize: 12,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.background,
      indicatorColor: colors.primarySoft,
      selectedIconTheme: IconThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFFB89BFF)
            : colors.primary,
      ),
      unselectedIconTheme: IconThemeData(color: colors.muted),
      selectedLabelTextStyle: TextStyle(
        color: colors.text,
        fontFamily: AppTypography.bodyFamily,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colors.muted,
        fontFamily: AppTypography.bodyFamily,
        fontSize: 12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: colors.muted),
      hintStyle: TextStyle(color: colors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.primarySoft,
      borderRadius: BorderRadius.circular(4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  );
}
