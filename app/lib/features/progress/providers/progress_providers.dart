import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/progress_api.dart';
import '../data/repositories/progress_repository.dart';
import '../domain/progress.dart';

final progressApiProvider = Provider<ProgressApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockProgressApi();
  }
  return RemoteProgressApi(ref.watch(dioProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(progressApiProvider));
});

final progressProvider = FutureProvider.autoDispose<Progress>((ref) {
  return ref.watch(progressRepositoryProvider).fetch();
});
