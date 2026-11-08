import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/theme/app_theme_controller.dart';
import 'package:named/app/theme/app_theme_family.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads and persists the selected theme family', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(appThemeControllerProvider.future),
      defaultAppThemeFamily,
    );

    await container
        .read(appThemeControllerProvider.notifier)
        .setFamily(AppThemeFamily.parchment);

    expect(prefs.getString(appThemeFamilyStorageKey), 'parchment');
    expect(
      container.read(appThemeControllerProvider).value,
      AppThemeFamily.parchment,
    );
  });

  test('falls back to cobalt for an unknown saved value', () {
    expect(AppThemeFamily.fromStorage('unknown'), AppThemeFamily.cobalt);
    expect(AppThemeFamily.fromStorage(null), AppThemeFamily.cobalt);
    expect(AppThemeFamily.fromStorage('plum'), AppThemeFamily.plum);
  });
}
