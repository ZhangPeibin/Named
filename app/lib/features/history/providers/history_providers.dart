import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/history_api.dart';
import '../data/repositories/history_repository.dart';
import '../domain/history_experience.dart';

class HistoryState {
  const HistoryState({required this.items, required this.nextCursor});

  final List<HistoryExperience> items;
  final String? nextCursor;
}

final historyApiProvider = Provider<HistoryApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockHistoryApi();
  }
  return RemoteHistoryApi(ref.watch(dioProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(historyApiProvider));
});

final historyControllerProvider =
    AsyncNotifierProvider.autoDispose<HistoryController, HistoryState>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    final page = await ref.read(historyRepositoryProvider).fetch();
    return HistoryState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null) {
      return;
    }
    final page = await ref
        .read(historyRepositoryProvider)
        .fetch(before: cursor);
    final existing = current.items.map((item) => item.id).toSet();
    state = AsyncData(
      HistoryState(
        items: [
          ...current.items,
          ...page.items.where((item) => !existing.contains(item.id)),
        ],
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> refresh() async {
    final page = await ref.read(historyRepositoryProvider).fetch();
    state = AsyncData(
      HistoryState(items: page.items, nextCursor: page.nextCursor),
    );
  }
}

final experienceDetailProvider = FutureProvider.autoDispose
    .family<HistoryExperience, String>((ref, id) {
      return ref.read(historyRepositoryProvider).fetchExperience(id);
    });
