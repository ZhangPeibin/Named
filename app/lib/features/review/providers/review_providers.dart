import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timeline/domain/timeline_item.dart';
import '../../words/domain/word_shelf.dart';
import '../../words/providers/words_providers.dart';

final reviewWordsProvider = FutureProvider.autoDispose<List<TimelineWordItem>>((
  ref,
) async {
  final shelf = await ref.watch(wordShelfProvider.future);
  final candidates = shelf.words
      .where((item) => item.status != WordShelfStatus.known)
      .where((item) => item.word != null)
      .take(3)
      .map(_asTimelineItem);
  return candidates.toList(growable: false);
});

TimelineWordItem _asTimelineItem(WordShelfItem item) {
  return TimelineWordItem(
    id: item.id,
    createdAt: item.lastSeenAt,
    inputText: null,
    wordId: item.id,
    word: item.word,
    audio: item.audio,
    conversationId: null,
  );
}

List<TimelineWordItem> selectReviewItems(
  List<TimelineWordItem> words, {
  Random? random,
  int count = 3,
}) {
  final shuffled = [...words]..shuffle(random ?? Random());
  return shuffled.take(count).toList(growable: false);
}
