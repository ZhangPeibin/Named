import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/practice_api.dart';
import '../data/repositories/practice_repository.dart';
import '../domain/practice_word.dart';

final practiceApiProvider = Provider<PracticeApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockPracticeApi();
  }
  return RemotePracticeApi(ref.watch(dioProvider));
});

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository(ref.watch(practiceApiProvider));
});

final practiceSessionProvider = FutureProvider.autoDispose<PracticeWord>((ref) {
  return ref.watch(practiceRepositoryProvider).next();
});
