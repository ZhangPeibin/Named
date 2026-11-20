enum AppThemeFamily {
  sky,
  cobalt,
  parchment,
  plum;

  static AppThemeFamily fromStorage(String? value) {
    return switch (value) {
      'parchment' => AppThemeFamily.parchment,
      'plum' => AppThemeFamily.plum,
      'sky' => AppThemeFamily.sky,
      _ => AppThemeFamily.sky,
    };
  }
}

const defaultAppThemeFamily = AppThemeFamily.sky;
