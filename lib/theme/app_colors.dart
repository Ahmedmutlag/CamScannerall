import 'package:flutter/material.dart';

/// The SafeScanPro palette (see design-spec.md), exposed as a
/// [ThemeExtension] so every screen reads colors from the Theme instead of
/// hardcoding hex values. Access via `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.backgroundPrimary,
    required this.primaryInk,
    required this.accentBrass,
    required this.accentScan,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.error,
  });

  /// Warm off-white background for every screen (never pure white).
  final Color backgroundPrimary;

  /// Primary buttons, important headings, active navigation icons.
  final Color primaryInk;

  /// Reserved exclusively for security-related elements: lock icon,
  /// "protected" badge, lock screen, successful-backup confirmation. Never
  /// used as a generic decorative accent.
  final Color accentBrass;

  /// Live camera scan line, "saved successfully" indicator, completed-step
  /// status.
  final Color accentScan;

  final Color textPrimary;
  final Color textSecondary;

  /// Divider lines between list rows — the deliberate replacement for
  /// matching-shadow Card widgets in lists (see design-spec.md §1/§3/§6).
  final Color divider;

  final Color error;

  static const light = AppColors(
    backgroundPrimary: Color(0xFFFAFAF7),
    primaryInk: Color(0xFF1B2A4A),
    accentBrass: Color(0xFFC08B3D),
    accentScan: Color(0xFF2F7A6B),
    textPrimary: Color(0xFF22221E),
    textSecondary: Color(0xFF5C5B54),
    divider: Color(0xFFE4E0D8),
    error: Color(0xFFB3423A),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.light;
  }

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? primaryInk,
    Color? accentBrass,
    Color? accentScan,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? error,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      primaryInk: primaryInk ?? this.primaryInk,
      accentBrass: accentBrass ?? this.accentBrass,
      accentScan: accentScan ?? this.accentScan,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      accentBrass: Color.lerp(accentBrass, other.accentBrass, t)!,
      accentScan: Color.lerp(accentScan, other.accentScan, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Fixed spacing scale (design-spec.md §3) — use these instead of ad-hoc
/// EdgeInsets/SizedBox values scattered across screens.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// The single border radius used for every field and button in the app.
class AppRadius {
  AppRadius._();
  static const double value = 8;
  static const BorderRadius radius = BorderRadius.all(Radius.circular(value));
}
