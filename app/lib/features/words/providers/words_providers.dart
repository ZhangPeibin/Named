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

final wordDetailsCacheProvider = Provider<Map<String, WordShelfItem>>((ref) {
  return {};
});

final wordLookupProvider = FutureProvider.autoDispose
    .family<WordShelfItem, String>((ref, text) {
      ref.keepAlive();
      return ref.watch(wordsRepositoryProvider).lookup(text, level: 'card');
    }, retry: (retryCount, error) => null);

final wordDetailsProvider = FutureProvider.autoDispose
    .family<WordShelfItem, String>((ref, wordId) async {
      ref.keepAlive();
      final cache = ref.watch(wordDetailsCacheProvider);
      final cached = cache[wordId];
      if (cached != null) {
        return cached;
      }
      final item = await ref
          .watch(wordsRepositoryProvider)
          .fetchDetails(wordId);
      cache[wordId] = item;
      return item;
    }, retry: (retryCount, error) => null);
