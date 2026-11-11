import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/translation_api.dart';
import '../data/repositories/translation_repository.dart';
import '../domain/translation.dart';

final translationApiProvider = Provider<TranslationApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockTranslationApi();
  }
  return RemoteTranslationApi(ref.watch(dioProvider));
});

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepository(ref.watch(translationApiProvider));
});

final translationProvider = FutureProvider.autoDispose
    .family<TranslationResult, String>((ref, text) {
      return ref.read(translationRepositoryProvider).translate(text);
    });
