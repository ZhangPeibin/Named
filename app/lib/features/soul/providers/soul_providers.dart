import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dio_provider.dart';
import '../data/api/soul_api.dart';
import '../data/repositories/soul_repository.dart';
import '../domain/soul.dart';

final soulApiProvider = Provider<SoulApi>((ref) {
  return RemoteSoulApi(ref.watch(dioProvider));
});

final soulRepositoryProvider = Provider<SoulRepository>((ref) {
  return SoulRepository(ref.watch(soulApiProvider));
});

final soulProvider = FutureProvider.autoDispose<Soul>((ref) {
  return ref.watch(soulRepositoryProvider).fetchSoul();
});
