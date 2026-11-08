import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/key_value_storage_provider.dart';
import '../../core/storage/key_value_storage.dart';
import 'app_theme_family.dart';

const appThemeFamilyStorageKey = 'app.theme.family';

Future<AppThemeFamily> loadSavedAppThemeFamily(KeyValueStorage storage) async {
  return AppThemeFamily.fromStorage(
    await storage.getString(appThemeFamilyStorageKey),
  );
}

final appThemeControllerProvider =
    AsyncNotifierProvider<AppThemeController, AppThemeFamily>(
      AppThemeController.new,
    );

class AppThemeController extends AsyncNotifier<AppThemeFamily> {
  @override
  Future<AppThemeFamily> build() async {
    try {
      return await loadSavedAppThemeFamily(ref.read(keyValueStorageProvider));
    } catch (_) {
      return defaultAppThemeFamily;
    }
  }

  Future<void> setFamily(AppThemeFamily family) async {
    final previous = state.value ?? defaultAppThemeFamily;
    if (previous == family) {
      return;
    }
    state = AsyncData(family);
    try {
      await ref
          .read(keyValueStorageProvider)
          .setString(appThemeFamilyStorageKey, family.name);
    } catch (_) {
      state = AsyncData(previous);
    }
  }
}
