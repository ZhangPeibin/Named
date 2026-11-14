import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/daily_api.dart';
import '../data/repositories/daily_repository.dart';
import '../domain/daily_read.dart';

final dailyApiProvider = Provider<DailyApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockDailyApi();
  }
  return RemoteDailyApi(ref.watch(dioProvider));
});

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.watch(dailyApiProvider));
});

final dailyReadProvider = FutureProvider.autoDispose
    .family<DailyRead, DateTime?>((ref, date) {
      return ref.watch(dailyRepositoryProvider).fetchToday(date: date);
    });
