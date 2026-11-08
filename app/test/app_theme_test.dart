import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/theme/app_colors.dart';
import 'package:named/app/theme/app_theme.dart';
import 'package:named/app/theme/app_theme_family.dart';

void main() {
  test('default light theme uses the cobalt palette', () {
    final theme = AppTheme.light();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppPalette.cobaltLight.canvas);
    expect(palette?.primary, AppPalette.cobaltLight.primary);
    expect(theme.colorScheme.primary, AppPalette.cobaltLight.primary);
  });

  test('default dark theme uses the cobalt palette', () {
    final theme = AppTheme.dark();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.cobaltDark.canvas);
    expect(palette?.primary, AppPalette.cobaltDark.primary);
    expect(theme.colorScheme.primary, AppPalette.cobaltDark.primary);
  });

  test('every theme family resolves to its own palette', () {
    expect(
      AppTheme.lightPaletteFor(AppThemeFamily.parchment).primary,
      AppPalette.parchmentLight.primary,
    );
    expect(
      AppTheme.darkPaletteFor(AppThemeFamily.parchment).primary,
      AppPalette.parchmentDark.primary,
    );
    expect(
      AppTheme.lightPaletteFor(AppThemeFamily.plum).primary,
      AppPalette.plumLight.primary,
    );
    expect(
      AppTheme.darkPaletteFor(AppThemeFamily.plum).primary,
      AppPalette.plumDark.primary,
    );
  });
}
