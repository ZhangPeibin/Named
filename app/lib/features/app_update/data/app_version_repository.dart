import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

import '../domain/app_version_check.dart';
import 'api/app_version_api.dart';

abstract interface class AppVersionRepository {
  Future<AppVersionCheck> checkVersion({bool forceUpdate = false});
}

class RemoteAppVersionRepository implements AppVersionRepository {
  const RemoteAppVersionRepository(this._api);

  final AppVersionApi _api;

  @override
  Future<AppVersionCheck> checkVersion({bool forceUpdate = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final dto = await _api.checkVersion(
      platform: _platformLabel(),
      version: packageInfo.version,
      build: int.tryParse(packageInfo.buildNumber) ?? 0,
    );
    return dto.toDomain();
  }

  String _platformLabel() {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return Platform.operatingSystem;
  }
}

/// Local mock for optional / force update dialogs when `USE_MOCK_API` is on.
class MockAppVersionRepository implements AppVersionRepository {
  const MockAppVersionRepository();

  @override
  Future<AppVersionCheck> checkVersion({bool forceUpdate = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return AppVersionCheck(
      platform: 'mock',
      currentVersion: '1.0.0',
      currentBuild: 1,
      latestVersion: '1.1.0',
      latestBuild: 2,
      minSupportedVersion: forceUpdate ? '1.1.0' : '1.0.0',
      minSupportedBuild: forceUpdate ? 2 : 1,
      updateAvailable: true,
      forceUpdate: forceUpdate,
      storeUrl: 'https://example.com/app',
      releaseNotes: forceUpdate
          ? 'This update is required to continue.'
          : 'Bug fixes and improvements.',
    );
  }
}
