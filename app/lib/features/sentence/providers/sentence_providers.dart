import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/sentence_api.dart';
import '../data/repositories/sentence_repository.dart';
import '../domain/sentence_detail.dart';

final sentenceApiProvider = Provider<SentenceApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockSentenceApi();
  }
  return RemoteSentenceApi(ref.watch(dioProvider));
});

final sentenceRepositoryProvider = Provider<SentenceRepository>((ref) {
  return SentenceRepository(ref.watch(sentenceApiProvider));
});

final sentenceDetailProvider = FutureProvider.autoDispose
    .family<SentenceDetail, String>((ref, text) {
      return ref.read(sentenceRepositoryProvider).lookup(text);
    });
