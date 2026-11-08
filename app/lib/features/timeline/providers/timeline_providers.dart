import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../../discover/providers/discover_providers.dart';
import '../../talk/providers/talk_providers.dart';
import '../data/api/timeline_api.dart';
import '../data/repositories/timeline_repository.dart';
import '../domain/timeline_item.dart';

class TimelineState {
  const TimelineState({required this.items, required this.nextCursor});

  final List<TimelineItem> items;
  final String? nextCursor;

  TimelineState copyWith({List<TimelineItem>? items, String? nextCursor}) {
    return TimelineState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

final timelineApiProvider = Provider<TimelineApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return const MockTimelineApi();
  }
  return RemoteTimelineApi(ref.watch(dioProvider));
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(timelineApiProvider));
});

final timelineControllerProvider =
    AsyncNotifierProvider.autoDispose<TimelineController, TimelineState>(
      TimelineController.new,
    );

class TimelineController extends AsyncNotifier<TimelineState> {
  @override
  Future<TimelineState> build() async {
    final page = await ref.read(timelineRepositoryProvider).fetch();
    return TimelineState(
      items: page.items.reversed.toList(),
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    final page = await ref.read(timelineRepositoryProvider).fetch();
    state = AsyncData(
      TimelineState(
        items: page.items.reversed.toList(),
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> loadEarlier() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null) {
      return;
    }
    final page = await ref
        .read(timelineRepositoryProvider)
        .fetch(before: cursor);
    final existing = current.items.map(_itemKey).toSet();
    final older = page.items
        .where((item) => !existing.contains(_itemKey(item)))
        .toList();
    state = AsyncData(
      TimelineState(
        items: [...older.reversed, ...current.items],
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<TimelineItem?> createNamed(String text) async {
    final discover = ref.read(discoverRepositoryProvider);
    var discovery = await discover.createText(text: text);

    if (discovery.needsConfirmation) {
      if (discovery.candidates.isNotEmpty) {
        discovery = await discover.focus(
          discoveryId: discovery.id,
          candidateId: discovery.candidates.first.id,
        );
      } else if (discovery.isScene) {
        discovery = await discover.focus(
          discoveryId: discovery.id,
          wholeScene: true,
        );
      }
    }

    final scene = discovery.scene;
    if (discovery.isScene && scene != null) {
      final item = TimelineSceneItem(
        id: discovery.id,
        createdAt: DateTime.now(),
        inputText: discovery.inputText ?? text,
        inputLanguage: discovery.inputLanguage,
        scene: scene,
        audio: discovery.sceneAudio,
        conversationId: null,
      );
      _appendItem(item);
      return item;
    }

    final word = discovery.word;
    if (word == null) {
      throw const ApiException(
        type: ApiExceptionType.badResponse,
        message:
            'No discovery result. Try naming one thing or describing a moment.',
      );
    }

    final item = TimelineWordItem(
      id: discovery.id,
      createdAt: DateTime.now(),
      inputText: discovery.inputText ?? text,
      wordId: discovery.wordId,
      word: word,
      audio: discovery.audio,
      conversationId: null,
    );
    _appendItem(item);
    return item;
  }

  void _appendItem(TimelineItem item) {
    final currentState = state.value;
    state = AsyncData(
      TimelineState(
        items: [...?currentState?.items, item],
        nextCursor: currentState?.nextCursor,
      ),
    );
  }

  Future<String> ensureConversation(TimelineWordItem item) async {
    if (item.conversationId != null) {
      return item.conversationId!;
    }
    final wordId = item.wordId;
    if (wordId == null) {
      throw const ApiException(
        type: ApiExceptionType.badResponse,
        message: 'This card has no word to talk about.',
      );
    }

    final conversation = await ref
        .read(talkRepositoryProvider)
        .createConversation(focusType: 'word', focusId: wordId);
    _updateWordItem(item.copyWith(conversationId: conversation.id));
    return conversation.id;
  }

  Future<String> ensureSceneConversation(TimelineSceneItem item) async {
    if (item.conversationId != null) {
      return item.conversationId!;
    }

    final conversation = await ref
        .read(talkRepositoryProvider)
        .createConversation(focusType: 'scene', focusId: item.id);
    _updateSceneItem(item.copyWith(conversationId: conversation.id));
    return conversation.id;
  }

  Future<void> afterTalk({
    required String conversationId,
    required String title,
  }) async {
    final config = ref.read(appConfigProvider);
    if (!config.useMockApi) {
      await refresh();
      return;
    }

    final conversation = await ref
        .read(talkRepositoryProvider)
        .fetch(conversationId);
    if (conversation.messages.isEmpty) {
      return;
    }
    final last = conversation.messages.last;
    final talk = TimelineTalkItem(
      id: conversationId,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      title: title,
      lastMessageRole: last.role,
      lastMessageText: last.text,
      messageCount: conversation.messages.length,
    );

    final current = state.value;
    if (current == null) {
      return;
    }
    final items =
        current.items
            .where(
              (item) =>
                  !(item is TimelineTalkItem &&
                      item.conversationId == conversationId),
            )
            .toList()
          ..add(talk);
    state = AsyncData(
      TimelineState(items: items, nextCursor: current.nextCursor),
    );
  }

  void _updateWordItem(TimelineWordItem updated) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      TimelineState(
        items: current.items
            .map(
              (item) => item is TimelineWordItem && item.id == updated.id
                  ? updated
                  : item,
            )
            .toList(),
        nextCursor: current.nextCursor,
      ),
    );
  }

  void _updateSceneItem(TimelineSceneItem updated) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      TimelineState(
        items: current.items
            .map(
              (item) => item is TimelineSceneItem && item.id == updated.id
                  ? updated
                  : item,
            )
            .toList(),
        nextCursor: current.nextCursor,
      ),
    );
  }

  String _itemKey(TimelineItem item) {
    return switch (item) {
      TimelineWordItem() => 'word:${item.id}',
      TimelineSceneItem() => 'scene:${item.id}',
      TimelineTalkItem() => 'talk:${item.id}',
    };
  }
}
