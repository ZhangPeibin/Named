enum ReaderThemeMode {
  system,
  light,
  dark;

  static ReaderThemeMode fromStorage(String? value) {
    return switch (value) {
      'light' => ReaderThemeMode.light,
      'dark' => ReaderThemeMode.dark,
      _ => ReaderThemeMode.system,
    };
  }

  String get storageValue => switch (this) {
    ReaderThemeMode.system => 'system',
    ReaderThemeMode.light => 'light',
    ReaderThemeMode.dark => 'dark',
  };
}
