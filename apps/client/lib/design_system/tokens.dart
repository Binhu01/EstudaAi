import 'package:flutter/material.dart';

@immutable
class AppColors {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.success,
    required this.successSoft,
    required this.successInk,
    required this.warning,
    required this.warningSoft,
    required this.warningInk,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.error,
    required this.errorSoft,
    required this.errorInk,
    required this.sidebar,
  });
  final Color primary,
      onPrimary,
      primarySoft,
      background,
      surface,
      text,
      muted,
      border;
  final Color success,
      successSoft,
      successInk,
      warning,
      warningSoft,
      warningInk;
  final Color accent,
      accentSoft,
      accentInk,
      error,
      errorSoft,
      errorInk,
      sidebar;
  static const white = Color(0xFFFFFFFF), scrim = Color(0xFF000000);
  static const heroFallback = Color(0xFF000000);
  static const heroScrimTop = Color(0xB8000000),
      heroScrimBottom = Color(0xDB000000);
  static const pixelInk = Color(0xFF312F27), pixelViolet = Color(0xFF8052FF);
  static const quizAnswers = [
    Color(0xFFB91C1C),
    Color(0xFF1D4ED8),
    Color(0xFFFDE047),
    Color(0xFF166534),
  ];
  static const shaderYellow = Color(0xFFD6CE36),
      shaderBlue = Color(0xFF0000D8),
      shaderViolet = Color(0xFF9147FF);
  static const onAccent = Color(0xFF312F27);
  static const light = AppColors(
    primary: Color(0xFF7040DF),
    onPrimary: white,
    primarySoft: Color(0xFFF0EAFF),
    background: Color(0xFFFAF9FC),
    surface: white,
    text: Color(0xFF17151C),
    muted: Color(0xFF635E70),
    border: Color(0xFFE1DDE8),
    sidebar: scrim,
    success: Color(0xFF15846E),
    successSoft: Color(0xFFE0F4EA),
    successInk: Color(0xFF145B40),
    warning: Color(0xFFFFB829),
    warningSoft: Color(0xFFFFF3D6),
    warningInk: Color(0xFF705000),
    accent: Color(0xFFFFB829),
    accentSoft: Color(0xFFFFF3D6),
    accentInk: Color(0xFF705000),
    error: Color(0xFFBD303E),
    errorSoft: Color(0xFFFFE7EB),
    errorInk: Color(0xFF912434),
  );
  static const dark = AppColors(
    primary: Color(0xFF8052FF),
    onPrimary: white,
    primarySoft: Color(0xFF231638),
    background: scrim,
    surface: Color(0xFF111114),
    text: white,
    muted: Color(0xFFBDBDBD),
    border: Color(0xFF2C2931),
    sidebar: scrim,
    success: Color(0xFF70D3AE),
    successSoft: Color(0xFF102F26),
    successInk: Color(0xFFA7E5C9),
    warning: Color(0xFFFFB829),
    warningSoft: Color(0xFF362A12),
    warningInk: Color(0xFFFFD685),
    accent: Color(0xFFFFB829),
    accentSoft: Color(0xFF362A12),
    accentInk: Color(0xFFFFD685),
    error: Color(0xFFFF939E),
    errorSoft: Color(0xFF35181F),
    errorInk: Color(0xFFFFBAC3),
  );
  Color get linkInk => background == scrim ? const Color(0xFFB89BFF) : primary;
  Color get accentText => background == scrim ? accent : accentInk;
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

abstract final class AurosColors {
  static const abyss = Color(0xFF012624),
      deep = Color(0xFF011D1C),
      kelp = Color(0xFF003734),
      mist = Color(0xFFEDFFFE),
      silver = Color(0xFFBBC7C6),
      lavender = Color(0xFFFDE9FF),
      cyan = Color(0xFFCBFFFC);
}

abstract final class GameColors {
  static const yellow = Color(0xFFFFC500),
      ink = Color(0xFF312F27),
      screen = Color(0xFFE9E4D9),
      screenInk = ink,
      violet = Color(0xFF7700FF),
      chassisGray = Color(0xFF788086);
}

abstract final class AppSpacing {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      lg = 16.0,
      xl = 24.0,
      xxl = 36.0,
      section = 60.0;
}

abstract final class AppRadius {
  static const card = 8.0, control = 6.0, pill = 999.0;
}

abstract final class AppElevation {
  static const flat = 0.0, floating = 4.0, modal = 8.0;
}

abstract final class AppShadows {
  static List<BoxShadow> card(AppColors colors) => const [];
}

abstract final class AppIcons {
  static const brand = Icons.auto_stories_rounded,
      home = Icons.space_dashboard_outlined;
  static const goal = Icons.flag_outlined, settings = Icons.tune_rounded;
  static const video = Icons.play_circle_outline_rounded,
      mindMap = Icons.account_tree_outlined;
  static const questions = Icons.quiz_outlined,
      flashcards = Icons.style_outlined;
  static const review = Icons.history_rounded,
      challenge = Icons.local_fire_department_outlined;
  static const forward = Icons.arrow_forward_rounded;
}

abstract final class AppAnimations {
  static const feedback = Duration(milliseconds: 180),
      shaderFrame = Duration(milliseconds: 100);
}

abstract final class AppTypography {
  static const headingFamily = 'Oswald', bodyFamily = 'Poppins';
  static const pixel = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 12,
    height: 1.8,
  );
  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: headingFamily,
      fontSize: 64,
      fontWeight: FontWeight.w500,
      height: 1.1,
      letterSpacing: 0,
    ),
    displayMedium: TextStyle(
      fontFamily: headingFamily,
      fontSize: 56,
      fontWeight: FontWeight.w500,
      height: 1.12,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontFamily: headingFamily,
      fontSize: 48,
      fontWeight: FontWeight.w500,
      height: 1.12,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontFamily: headingFamily,
      fontSize: 40,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontFamily: headingFamily,
      fontSize: 34,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontFamily: headingFamily,
      fontSize: 28,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontFamily: headingFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontFamily: headingFamily,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontFamily: headingFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.65,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0,
    ),
  );
}
