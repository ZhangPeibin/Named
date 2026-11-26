import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_config_provider.dart';
import '../providers/dio_provider.dart';
import 'pronunciation_cache.dart';
import 'speech_api.dart';
import 'speech_repository.dart';
import 'speech_url_cache.dart';
import 'voice_input.dart';

final speechApiProvider = Provider<SpeechApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockSpeechApi();
  }
  return RemoteSpeechApi(ref.watch(dioProvider));
});

final speechRepositoryProvider = Provider<SpeechRepository>((ref) {
  return SpeechRepository(ref.watch(speechApiProvider));
});

final speechUrlCacheProvider = Provider<SpeechUrlCache>((ref) {
  return SpeechUrlCache(ref.watch(speechRepositoryProvider));
});

final pronunciationCacheProvider = Provider<PronunciationCache>((ref) {
  return PronunciationCache(ref.watch(speechRepositoryProvider));
});

final voiceInputProvider = Provider<VoiceInput>((ref) {
  final input = DeviceVoiceInput(ref.watch(speechRepositoryProvider));
  ref.onDispose(() => unawaited(input.dispose()));
  return input;
});
