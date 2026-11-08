enum AppThemeFamily {
  cobalt,
  parchment,
  plum;

  static AppThemeFamily fromStorage(String? value) {
    return switch (value) {
      'parchment' => AppThemeFamily.parchment,
      'plum' => AppThemeFamily.plum,
      _ => AppThemeFamily.cobalt,
    };
  }
}

const defaultAppThemeFamily = AppThemeFamily.cobalt;
