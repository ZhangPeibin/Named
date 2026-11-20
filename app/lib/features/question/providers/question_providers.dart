import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/question_api.dart';
import '../data/repositories/question_repository.dart';

final questionApiProvider = Provider<QuestionApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockQuestionApi();
  }
  return RemoteQuestionApi(ref.watch(dioProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(questionApiProvider));
});
