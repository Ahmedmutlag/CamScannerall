import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the single, explicit SafeScanPro theme (see design-spec.md).
/// There is one fixed light palette — no seed-color derivation, no dark
/// variant was specified, so none is invented; if a dark mode is wanted
/// later, it needs its own explicit palette from design, not a guess.
class AppTheme {
  AppTheme._();

  /// [languageCode] picks the typeface: Manrope for Latin text, Cairo for
  /// Arabic — both bundled offline (see pubspec.yaml `assets:` and
  /// [configureGoogleFonts]), so neither requires network access.
  static ThemeData build({required String languageCode}) {
    const colors = AppColors.light;
    final isArabic = languageCode == 'ar';

    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : GoogleFonts.manropeTextTheme();

    final textTheme = baseTextTheme
        .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary)
        .copyWith(
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700, color: colors.textPrimary),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700, color: colors.textPrimary),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600, color: colors.textPrimary),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600, color: colors.textPrimary),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600, color: colors.textPrimary),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500, color: colors.textPrimary),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.textPrimary),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          bodySmall: baseTextTheme.bodySmall?.copyWith(color: colors.textSecondary),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600, color: colors.textPrimary),
        );

    final colorScheme = ColorScheme.light(
      primary: colors.primaryInk,
      onPrimary: colors.backgroundPrimary,
      secondary: colors.accentScan,
      onSecondary: colors.backgroundPrimary,
      error: colors.error,
      onError: colors.backgroundPrimary,
      surface: colors.backgroundPrimary,
      onSurface: colors.textPrimary,
      outline: colors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.backgroundPrimary,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Cards are the exception, not the rule (design-spec.md §1) — no
      // shadow, just a hairline border, reserved for the rare permitted
      // case (e.g. a single onboarding welcome card).
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radius,
          side: BorderSide(color: colors.divider),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.primaryInk,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppRadius.radius,
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radius,
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radius,
          borderSide: BorderSide(color: colors.primaryInk, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryInk,
          foregroundColor: colors.backgroundPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryInk,
          side: BorderSide(color: colors.divider),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryInk,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryInk,
        foregroundColor: colors.backgroundPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.backgroundPrimary,
        selectedColor: colors.primaryInk,
        labelStyle: TextStyle(color: colors.textPrimary),
        secondaryLabelStyle: TextStyle(color: colors.backgroundPrimary),
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accentScan),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accentScan : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accentScan.withValues(alpha: 0.5)
              : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primaryInk : colors.textSecondary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primaryInk : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.primaryInk,
        contentTextStyle: TextStyle(color: colors.backgroundPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radius),
      ),
      extensions: const [colors],
    );
  }

  /// Must run once before the first frame (see main.dart): forces
  /// `google_fonts` to use the offline-bundled TTFs in `assets/fonts/`
  /// instead of fetching from Google's servers, per the design spec's
  /// "no network required for any core function" principle.
  static void configureGoogleFonts() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }
}
