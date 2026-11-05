import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/talk_api.dart';
import '../data/repositories/talk_repository.dart';
import '../domain/talk.dart';

final talkApiProvider = Provider<TalkApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockTalkApi();
  }
  return RemoteTalkApi(ref.watch(dioProvider));
});

final talkRepositoryProvider = Provider<TalkRepository>((ref) {
  return TalkRepository(ref.watch(talkApiProvider));
});

final conversationProvider = FutureProvider.autoDispose
    .family<Conversation, String>((ref, conversationId) {
      return ref.watch(talkRepositoryProvider).fetch(conversationId);
    });
