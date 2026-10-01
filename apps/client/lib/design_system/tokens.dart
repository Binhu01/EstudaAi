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
  static const white = Color(0xFFFFFFFF);
  static const scrim = Color(0xFF000000);
  static const shaderYellow = Color(0xFFD6CE36);
  static const shaderBlue = Color(0xFF0000D8);
  static const shaderViolet = Color(0xFF9147FF);
  static const onAccent = Color(0xFF431407);
  static const light = AppColors(
    primary: Color(0xFF2563EB),
    onPrimary: white,
    primarySoft: Color(0xFFDBEAFE),
    background: Color(0xFFF8FAFC),
    surface: white,
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF16A34A),
    successSoft: Color(0xFFDCFCE7),
    successInk: Color(0xFF166534),
    warning: Color(0xFFEAB308),
    warningSoft: Color(0xFFFEF9C3),
    warningInk: Color(0xFF713F12),
    accent: Color(0xFFF97316),
    accentSoft: Color(0xFFFFEDD5),
    accentInk: Color(0xFF7C2D12),
    error: Color(0xFFDC2626),
    errorSoft: Color(0xFFFEE2E2),
    errorInk: Color(0xFF991B1B),
    sidebar: Color(0xFF1D4ED8),
  );
  static const dark = AppColors(
    primary: Color(0xFF91B5FF),
    onPrimary: Color(0xFF102454),
    primarySoft: Color(0xFF172E57),
    background: Color(0xFF0B1220),
    surface: Color(0xFF121D30),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFFB0BCD0),
    border: Color(0xFF2A3850),
    success: Color(0xFF60C68B),
    successSoft: Color(0xFF16382A),
    successInk: Color(0xFFB3EFCA),
    warning: Color(0xFFE3BF53),
    warningSoft: Color(0xFF39301A),
    warningInk: Color(0xFFF4DA86),
    accent: Color(0xFFF4AA74),
    accentSoft: Color(0xFF3A251B),
    accentInk: Color(0xFFFFCEAC),
    error: Color(0xFFF49494),
    errorSoft: Color(0xFF3B2029),
    errorInk: Color(0xFFFFBDBD),
    sidebar: Color(0xFF102954),
  );
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

abstract final class AppSpacing {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      lg = 16.0,
      xl = 24.0,
      xxl = 32.0,
      section = 48.0;
}

abstract final class AppRadius {
  static const card = 8.0, control = 8.0, pill = 999.0;
}

abstract final class AppElevation {
  static const flat = 0.0, floating = 4.0, modal = 8.0;
}

abstract final class AppShadows {
  static List<BoxShadow> card(AppColors colors) => [
    BoxShadow(
      color: colors.text.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];
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
  static const feedback = Duration(milliseconds: 180);
  static const shaderFrame = Duration(milliseconds: 100);
}

abstract final class AppTypography {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, letterSpacing: 0),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0,
    ),
  );
}
