import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/assistant_api.dart';
import '../data/repositories/assistant_repository.dart';

final assistantApiProvider = Provider<AssistantApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockAssistantApi();
  }
  return RemoteAssistantApi(ref.watch(dioProvider));
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(assistantApiProvider));
});
