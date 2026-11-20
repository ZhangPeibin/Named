import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timeline/domain/timeline_item.dart';
import '../../words/domain/word_shelf.dart';
import '../../words/providers/words_providers.dart';

final reviewWordsProvider = FutureProvider.autoDispose<List<TimelineWordItem>>((
  ref,
) async {
  final shelf = await ref.watch(wordShelfProvider.future);
  return selectReviewItems(shelf.words);
});

/// Number of words the single timeline entry point should offer right now.
final dueReviewCountProvider = Provider.autoDispose<int>((ref) {
  final shelf = ref.watch(wordShelfProvider).value;
  if (shelf == null) {
    return 0;
  }
  return dueReviewWords(shelf.words).length;
});

/// Picks up to [count] words to review.
///
/// Never-reviewed words come first, then the order the backend already
/// supplied (`needs_review` → `attempted` → `growing`). Selection is
/// deterministic so the same shelf always produces the same set.
List<WordShelfItem> dueReviewWords(List<WordShelfItem> words, {int count = 3}) {
  final eligible = words
      .where((item) => item.status != WordShelfStatus.known)
      .where((item) => item.word != null)
      .toList(growable: false);
  final unseen = eligible.where((item) => item.lastReviewedAt == null);
  final reviewed = eligible.where((item) => item.lastReviewedAt != null);
  return [...unseen, ...reviewed].take(count).toList(growable: false);
}

List<TimelineWordItem> selectReviewItems(
  List<WordShelfItem> words, {
  int count = 3,
}) {
  return dueReviewWords(
    words,
    count: count,
  ).map(_asTimelineItem).toList(growable: false);
}

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
