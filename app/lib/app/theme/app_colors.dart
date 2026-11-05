import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.warm,
    required this.line,
    required this.warningSurface,
    required this.warningText,
    required this.error,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color warm;
  final Color line;
  final Color warningSurface;
  final Color warningText;
  final Color error;

  static const light = AppPalette(
    canvas: Color(0xFFF5F2E9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE5E9DF),
    primary: Color(0xFF526B4B),
    primaryPressed: Color(0xFF43583E),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF30372F),
    muted: Color(0xFF646A60),
    accent: Color(0xFFA7BC96),
    warm: Color(0xFFE8DDCC),
    line: Color(0xFFD4D8CD),
    warningSurface: Color(0xFFF1E6D7),
    warningText: Color(0xFF77512D),
    error: Color(0xFFA13D32),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF1C211D),
    surface: Color(0xFF252C26),
    surfaceMuted: Color(0xFF303930),
    primary: Color(0xFFA7BC96),
    primaryPressed: Color(0xFF8FA57F),
    onPrimary: Color(0xFF1C211D),
    ink: Color(0xFFE9E8DF),
    muted: Color(0xFFB8BDB2),
    accent: Color(0xFF718568),
    warm: Color(0xFF3A352D),
    line: Color(0xFF485246),
    warningSurface: Color(0xFF3C342A),
    warningText: Color(0xFFE8DDCC),
    error: Color(0xFFE6A09A),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? ink,
    Color? muted,
    Color? accent,
    Color? warm,
    Color? line,
    Color? warningSurface,
    Color? warningText,
    Color? error,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      warm: warm ?? this.warm,
      line: line ?? this.line,
      warningSurface: warningSurface ?? this.warningSurface,
      warningText: warningText ?? this.warningText,
      error: error ?? this.error,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) {
      return this;
    }
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      warm: Color.lerp(warm, other.warm, t)!,
      line: Color.lerp(line, other.line, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Raw light-theme values kept for older shared widgets. New feature code must
/// read semantic colors from [AppPalette] through [AppPaletteContext].
class AppColors {
  const AppColors._();

  static const brand = Color(0xFF526B4B);
  static const brandSoft = Color(0xFF718568);
  static const brandDark = Color(0xFF43583E);

  static const success = Color(0xFF526B4B);
  static const warning = Color(0xFF77512D);
  static const error = Color(0xFFA13D32);

  static const textPrimary = Color(0xFF30372F);
  static const textSecondary = Color(0xFF646A60);
  static const textMuted = Color(0xFF646A60);
  static const textOnBrand = Color(0xFFFFFFFF);

  static const border = Color(0xFFD4D8CD);
  static const borderLight = Color(0xFFE5E9DF);
  static const dividerLine = Color(0xFFD4D8CD);
  static const inputBorder = Color(0xFFC5CABF);

  static const selectedBg = Color(0xFFE5E9DF);
  static const sendCodeDisabledBg = Color(0xFFE5E9DF);
  static const tileChevron = Color(0xFFA7BC96);
  static const listSubtitle = Color(0xFF646A60);
  static const lightSurface = Color(0xFFFFFFFF);
}
