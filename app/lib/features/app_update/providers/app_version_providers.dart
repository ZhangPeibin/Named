import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/app_version_api.dart';
import '../data/app_version_repository.dart';
import '../domain/app_version_check.dart';

final appVersionApiProvider = Provider<AppVersionApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppVersionApi(
    ref.watch(dioProvider),
    checkPath: config.appVersionCheckPath,
  );
});

final appVersionRepositoryProvider = Provider<AppVersionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockAppVersionRepository();
  }
  return RemoteAppVersionRepository(ref.watch(appVersionApiProvider));
});

final appVersionCheckProvider = FutureProvider.family<AppVersionCheck, bool>((
  ref,
  forceUpdate,
) {
  return ref
      .watch(appVersionRepositoryProvider)
      .checkVersion(forceUpdate: forceUpdate);
});
