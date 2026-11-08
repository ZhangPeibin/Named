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

  static const cobaltLight = AppPalette(
    canvas: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE8EFF7),
    primary: Color(0xFF2F4A6B),
    primaryPressed: Color(0xFF243950),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF232A31),
    muted: Color(0xFF5F6B76),
    accent: Color(0xFFB05230),
    warm: Color(0xFFF0E5D8),
    line: Color(0xFFD9E1E9),
    warningSurface: Color(0xFFF4E5D2),
    warningText: Color(0xFF7A4C2A),
    error: Color(0xFFA13D32),
  );

  static const cobaltDark = AppPalette(
    canvas: Color(0xFF171A1D),
    surface: Color(0xFF20252A),
    surfaceMuted: Color(0xFF2A3138),
    primary: Color(0xFFA9C2DC),
    primaryPressed: Color(0xFF8FA9C4),
    onPrimary: Color(0xFF171A1D),
    ink: Color(0xFFE7EBEF),
    muted: Color(0xFFAAB3BC),
    accent: Color(0xFFE09A74),
    warm: Color(0xFF352B24),
    line: Color(0xFF343D45),
    warningSurface: Color(0xFF3A2F25),
    warningText: Color(0xFFF0DCC8),
    error: Color(0xFFE6A09A),
  );

  static const parchmentLight = AppPalette(
    canvas: Color(0xFFF8F4EC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFE7DA),
    primary: Color(0xFF2B2924),
    primaryPressed: Color(0xFF1E1D19),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF27251F),
    muted: Color(0xFF6D675D),
    accent: Color(0xFFB05230),
    warm: Color(0xFFF1E2D0),
    line: Color(0xFFE3DACB),
    warningSurface: Color(0xFFF4E5D2),
    warningText: Color(0xFF7A4C2A),
    error: Color(0xFFA13D32),
  );

  static const parchmentDark = AppPalette(
    canvas: Color(0xFF1A1917),
    surface: Color(0xFF24221F),
    surfaceMuted: Color(0xFF302C27),
    primary: Color(0xFFEADCC7),
    primaryPressed: Color(0xFFD8C8B2),
    onPrimary: Color(0xFF1A1917),
    ink: Color(0xFFF2EDE4),
    muted: Color(0xFFB8AFA2),
    accent: Color(0xFFD9845C),
    warm: Color(0xFF3A3028),
    line: Color(0xFF433D35),
    warningSurface: Color(0xFF3D3025),
    warningText: Color(0xFFEADCC7),
    error: Color(0xFFE6A09A),
  );

  static const plumLight = AppPalette(
    canvas: Color(0xFFF6F1E9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFE5DC),
    primary: Color(0xFF5B3A43),
    primaryPressed: Color(0xFF472C34),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF2C2525),
    muted: Color(0xFF6F6460),
    accent: Color(0xFFB05230),
    warm: Color(0xFFF1E2D2),
    line: Color(0xFFE2D7C9),
    warningSurface: Color(0xFFF5E7D5),
    warningText: Color(0xFF7A4C2A),
    error: Color(0xFFA13D32),
  );

  static const plumDark = AppPalette(
    canvas: Color(0xFF1A1718),
    surface: Color(0xFF241F20),
    surfaceMuted: Color(0xFF302829),
    primary: Color(0xFFE3C4C7),
    primaryPressed: Color(0xFFC7A3AA),
    onPrimary: Color(0xFF1A1718),
    ink: Color(0xFFF1E9E3),
    muted: Color(0xFFB9ADA8),
    accent: Color(0xFFE0A183),
    warm: Color(0xFF3A2D2A),
    line: Color(0xFF433839),
    warningSurface: Color(0xFF3C3028),
    warningText: Color(0xFFF0DCC8),
    error: Color(0xFFE6A09A),
  );

  static const light = cobaltLight;
  static const dark = cobaltDark;

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

  static const brand = Color(0xFF2F4A6B);
  static const brandSoft = Color(0xFF8FA9C4);
  static const brandDark = Color(0xFF243950);

  static const success = Color(0xFF3F6B58);
  static const warning = Color(0xFF7A4C2A);
  static const error = Color(0xFFA13D32);

  static const textPrimary = Color(0xFF232A31);
  static const textSecondary = Color(0xFF5F6B76);
  static const textMuted = Color(0xFF5F6B76);
  static const textOnBrand = Color(0xFFFFFFFF);

  static const border = Color(0xFFD9E1E9);
  static const borderLight = Color(0xFFE8EFF7);
  static const dividerLine = Color(0xFFD9E1E9);
  static const inputBorder = Color(0xFFC9D4DF);

  static const selectedBg = Color(0xFFE8EFF7);
  static const sendCodeDisabledBg = Color(0xFFE8EFF7);
  static const tileChevron = Color(0xFF2F4A6B);
  static const listSubtitle = Color(0xFF5F6B76);
  static const lightSurface = Color(0xFFFFFFFF);
}
