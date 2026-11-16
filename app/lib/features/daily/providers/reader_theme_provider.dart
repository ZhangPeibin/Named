import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/key_value_storage_provider.dart';
import '../domain/reader_theme.dart';

const readerThemeStorageKey = 'daily.readerTheme';

final readerThemeProvider =
    AsyncNotifierProvider<ReaderThemeController, ReaderThemeMode>(
      ReaderThemeController.new,
    );

class ReaderThemeController extends AsyncNotifier<ReaderThemeMode> {
  @override
  Future<ReaderThemeMode> build() async {
    final value = await ref
        .read(keyValueStorageProvider)
        .getString(readerThemeStorageKey);
    return ReaderThemeMode.fromStorage(value);
  }

  Future<void> setMode(ReaderThemeMode mode) async {
    state = AsyncData(mode);
    await ref
        .read(keyValueStorageProvider)
        .setString(readerThemeStorageKey, mode.storageValue);
  }
}
