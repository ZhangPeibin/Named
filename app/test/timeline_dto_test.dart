import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/data/dto/timeline_dto.dart';
import 'package:named/features/timeline/domain/timeline_item.dart';

void main() {
  test('parses word and talk timeline items', () {
    final page = TimelineResponseDto.fromJson({
      'items': [
        {
          'type': 'talk',
          'id': 'conversation-1',
          'created_at': '2026-11-05T10:00:00',
          'conversation_id': 'conversation-1',
          'title': 'tree',
          'focus_type': 'word',
          'focus_id': 'word-1',
          'last_message': {
            'role': 'assistant',
            'text': 'What did you notice?',
            'created_at': '2026-11-05T10:01:00',
          },
          'message_count': 2,
        },
        {
          'type': 'word',
          'id': 'discovery-1',
          'created_at': '2026-11-05T09:00:00',
          'input_text': '树',
          'status': 'ready',
          'focus_kind': 'word',
          'word_id': 'word-1',
          'conversation_id': 'conversation-1',
          'word': {
            'spelling': 'tree',
            'ipa': {'us': '/triː/'},
            'pos': ['noun'],
            'senses': [
              {
                'definition_en': 'a tall plant',
                'definition_zh': '树',
                'example_en': 'The tree is old.',
                'example_zh': '这棵树很老了。',
              },
            ],
            'grammar': 'countable',
            'related': ['leaf'],
            'scene_extensions': ['under a tree'],
          },
        },
      ],
      'next_cursor': '2026-11-05T09:00:00',
    }).toDomain();

    expect(page.items, hasLength(2));
    expect(page.nextCursor, '2026-11-05T09:00:00');
    expect(page.items.first, isA<TimelineTalkItem>());
    expect(page.items.last, isA<TimelineWordItem>());
    final word = page.items.last as TimelineWordItem;
    expect(word.word?.spelling, 'tree');
    expect(word.conversationId, 'conversation-1');
  });
}
