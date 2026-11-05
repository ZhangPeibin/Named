import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/key_value_storage.dart';
import '../storage/shared_preferences_key_value_storage.dart';

/// Holds the singleton `SharedPreferences` instance. Overridden in `main` after
/// `SharedPreferences.getInstance()` resolves, and overridden again in tests
/// with `SharedPreferences.setMockInitialValues(...)`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at startup.',
  );
});

final keyValueStorageProvider = Provider<KeyValueStorage>((ref) {
  return SharedPreferencesKeyValueStorage(ref.watch(sharedPreferencesProvider));
});
