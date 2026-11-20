import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:named/features/daily/domain/reader_theme.dart';
import 'package:named/features/daily/providers/reader_theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads and persists the reader theme', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(readerThemeProvider.future),
      ReaderThemeMode.system,
    );
    await container
        .read(readerThemeProvider.notifier)
        .setMode(ReaderThemeMode.dark);

    expect(prefs.getString(readerThemeStorageKey), 'dark');
    expect(container.read(readerThemeProvider).value, ReaderThemeMode.dark);
  });
}
