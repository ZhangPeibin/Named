import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dio_provider.dart';
import 'audio_bytes_api.dart';

final audioBytesApiProvider = Provider<AudioBytesApi>((ref) {
  return RemoteAudioBytesApi(ref.watch(dioProvider));
});
