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

  /// Reserved for a small set of meaningful confirmations (e.g. a
  /// successful-backup snackbar). Never used as a generic decorative accent.
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
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
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

  /// The softer, more rounded radius used by colorful pastel cards
  /// (Home tools, Print Documents slots, folder/document cards) — see
  /// [PastelPalette].
  static const double cardValue = 16;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(cardValue),
  );
}

/// A fixed set of pastel background/icon-color pairs, used for the
/// colorful rounded-card look (folders, documents, home tools, print
/// slots) introduced after Ahmed shared a reference design. Each card
/// picks a color deterministically from an id/name so it stays the same
/// color across rebuilds without needing to store a color explicitly.
class PastelPalette {
  PastelPalette._();

  static const List<(Color background, Color foreground)> _pairs = [
    (Color(0xFFDCEEFB), Color(0xFF1976D2)),
    (Color(0xFFDCF5F0), Color(0xFF0E9384)),
    (Color(0xFFFFF1D6), Color(0xFFB8860B)),
    (Color(0xFFEFE0FB), Color(0xFF8E24AA)),
    (Color(0xFFFBDDE7), Color(0xFFD81B60)),
    (Color(0xFFFCE8D6), Color(0xFFE65100)),
  ];

  static (Color background, Color foreground) forSeed(String seed) {
    final index = seed.isEmpty
        ? 0
        : seed.codeUnits.fold<int>(0, (a, b) => a + b) % _pairs.length;
    return _pairs[index];
  }

  /// The soft drop shadow every pastel card shares, giving them the
  /// slightly raised, glossy look from the reference — a deliberate
  /// departure from the earlier flat/hairline-only card style.
  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
