import '../storage/key_value_storage.dart';
import '../storage/secure_storage.dart';

/// Clears leftover Keychain credentials after an iOS reinstall.
///
/// iOS may keep Keychain items after the app is deleted. SharedPreferences
/// (and therefore this install marker) are wiped on uninstall, so a missing
/// marker means this is a fresh install and secure storage should be cleared
/// to avoid "still signed in after reinstall".
///
/// Call only on iOS. Other platforms should no-op (see [main.dart]).
class AppInstallGuard {
  const AppInstallGuard({
    required KeyValueStorage keyValueStorage,
    required SecureStorage secureStorage,
  }) : _keyValueStorage = keyValueStorage,
       _secureStorage = secureStorage;

  static const installMarkerKey = 'app.install.marker';

  final KeyValueStorage _keyValueStorage;
  final SecureStorage _secureStorage;

  Future<void> ensureCurrentInstall() async {
    final hasInstallMarker = await _keyValueStorage.containsKey(
      installMarkerKey,
    );

    if (hasInstallMarker) {
      return;
    }

    await _secureStorage.deleteAll();
    await _keyValueStorage.setBool(installMarkerKey, true);
  }
}
