import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/theme/app_colors.dart';
import 'package:named/app/theme/app_theme.dart';

void main() {
  test('light theme exposes the warm editorial palette', () {
    final theme = AppTheme.light();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppPalette.light.canvas);
    expect(palette?.primary, AppPalette.light.primary);
    expect(theme.colorScheme.primary, AppPalette.light.primary);
  });

  test('dark theme exposes the forest palette', () {
    final theme = AppTheme.dark();
    final palette = theme.extension<AppPalette>();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppPalette.dark.canvas);
    expect(palette?.primary, AppPalette.dark.primary);
    expect(theme.colorScheme.primary, AppPalette.dark.primary);
  });
}
