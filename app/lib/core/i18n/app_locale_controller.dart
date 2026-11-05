import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../providers/key_value_storage_provider.dart';
import '../storage/key_value_storage.dart';

const appLocaleStorageKey = 'app.locale';
const defaultAppLocale = AppLocale.en;

AppLocale parseSavedAppLocale(String? raw) {
  return switch (raw) {
    'zh' => AppLocale.zh,
    'en' || null || '' => AppLocale.en,
    _ => AppLocale.en,
  };
}

Future<AppLocale> loadSavedAppLocale(KeyValueStorage storage) async {
  return parseSavedAppLocale(await storage.getString(appLocaleStorageKey));
}

final appLocaleControllerProvider =
    AsyncNotifierProvider<AppLocaleController, AppLocale>(
      AppLocaleController.new,
    );

class AppLocaleController extends AsyncNotifier<AppLocale> {
  @override
  Future<AppLocale> build() async {
    return LocaleSettings.currentLocale;
  }

  Future<void> setLocale(AppLocale locale) async {
    final previous = state.value ?? LocaleSettings.currentLocale;
    state = AsyncData(locale);
    try {
      await ref
          .read(keyValueStorageProvider)
          .setString(appLocaleStorageKey, locale.languageCode);
      await LocaleSettings.setLocale(locale);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      await LocaleSettings.setLocale(previous);
    }
  }
}
