import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/theme/app_colors.dart';
import 'package:named/app/theme/app_theme.dart';
import 'package:named/app/theme/app_theme_family.dart';

void main() {
  test('default light theme uses the sky palette', () {
    final theme = AppTheme.light();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppPalette.skyLight.canvas);
    expect(palette?.primary, AppPalette.skyLight.primary);
    expect(theme.colorScheme.primary, AppPalette.skyLight.primary);
  });

  test('default dark theme uses the sky palette', () {
    final theme = AppTheme.dark();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.skyDark.canvas);
    expect(palette?.primary, AppPalette.skyDark.primary);
    expect(theme.colorScheme.primary, AppPalette.skyDark.primary);
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
    expect(
      AppTheme.lightPaletteFor(AppThemeFamily.sky).primary,
      AppPalette.skyLight.primary,
    );
    expect(
      AppTheme.darkPaletteFor(AppThemeFamily.sky).primary,
      AppPalette.skyDark.primary,
    );
  });
}
