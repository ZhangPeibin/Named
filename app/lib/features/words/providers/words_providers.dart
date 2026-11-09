import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/words_api.dart';
import '../data/repositories/words_repository.dart';
import '../domain/word_shelf.dart';

final wordsApiProvider = Provider<WordsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockWordsApi();
  }
  return RemoteWordsApi(ref.watch(dioProvider));
});

final wordsRepositoryProvider = Provider<WordsRepository>((ref) {
  return WordsRepository(ref.watch(wordsApiProvider));
});

final wordShelfProvider = FutureProvider.autoDispose<WordShelf>((ref) {
  return ref.watch(wordsRepositoryProvider).fetch();
});
