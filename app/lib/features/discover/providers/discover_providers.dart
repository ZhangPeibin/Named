import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/discover_api.dart';
import '../data/repositories/discover_repository.dart';
import '../domain/discover.dart';

final discoverApiProvider = Provider<DiscoverApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockDiscoverApi();
  }
  return RemoteDiscoverApi(ref.watch(dioProvider));
});

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(ref.watch(discoverApiProvider));
});

final discoveryProvider = FutureProvider.autoDispose.family<Discovery, String>((
  ref,
  discoveryId,
) {
  return ref.watch(discoverRepositoryProvider).fetch(discoveryId);
});
