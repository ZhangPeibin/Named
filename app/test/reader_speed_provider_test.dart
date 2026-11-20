import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:named/features/daily/providers/reader_speed_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads, clamps, and persists the reader speed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(await container.read(readerSpeedProvider.future), 1.0);

    await container.read(readerSpeedProvider.notifier).setRate(0.8);
    expect(prefs.getInt('daily.readerSpeedPercent'), 80);
    expect(container.read(readerSpeedProvider).value, 0.8);

    await container.read(readerSpeedProvider.notifier).setRate(2.0);
    expect(container.read(readerSpeedProvider).value, 1.5);
  });
}
