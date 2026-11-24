import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/timeline_item.dart';
import 'timeline_providers.dart';

class TimelineFeedState {
  const TimelineFeedState({required this.items, required this.nextCursor});

  final List<TimelineItem> items;
  final String? nextCursor;
}

final timelineFeedControllerProvider = AsyncNotifierProvider.autoDispose
    .family<TimelineFeedController, TimelineFeedState, String>(
      (type) => TimelineFeedController(type),
    );

class TimelineFeedController extends AsyncNotifier<TimelineFeedState> {
  TimelineFeedController(this.type);

  final String type;

  @override
  Future<TimelineFeedState> build() async {
    final page = await ref.read(timelineRepositoryProvider).fetch(type: type);
    return TimelineFeedState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> refresh() async {
    final page = await ref.read(timelineRepositoryProvider).fetch(type: type);
    state = AsyncData(
      TimelineFeedState(items: page.items, nextCursor: page.nextCursor),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null) {
      return;
    }
    final page = await ref
        .read(timelineRepositoryProvider)
        .fetch(type: type, before: cursor);
    final existing = current.items.map(_itemKey).toSet();
    final older = page.items
        .where((item) => !existing.contains(_itemKey(item)))
        .toList();
    state = AsyncData(
      TimelineFeedState(
        items: [...current.items, ...older],
        nextCursor: page.nextCursor,
      ),
    );
  }

  String _itemKey(TimelineItem item) {
    return switch (item) {
      TimelineWordItem() => 'word:${item.id}',
      TimelineSceneItem() => 'scene:${item.id}',
      TimelineTalkItem() => 'talk:${item.id}',
      TimelineDailyItem() => 'daily:${item.id}',
      TimelineQuestionItem() => 'question:${item.id}',
    };
  }
}
