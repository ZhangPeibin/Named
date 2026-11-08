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

  test('parses scene timeline items with audio', () {
    final page = TimelineResponseDto.fromJson({
      'items': [
        {
          'type': 'scene',
          'id': 'discovery-scene',
          'created_at': '2026-11-05T11:00:00',
          'input_text': 'I very like the tree.',
          'input_language': 'en',
          'audio': {'url': '/api/v1/audio/scene.mp3', 'status': 'ready'},
          'scene': {
            'natural_english': 'I really like the tree.',
            'key_chunks': [
              {
                'phrase': 'really like',
                'meaning_native': '非常喜欢',
                'example_en': 'I really like this song.',
              },
            ],
            'key_words': ['really', 'tree'],
            'correction': {
              'original': 'I very like the tree.',
              'suggestion': 'I really like the tree.',
              'note': 'Use really like.',
            },
          },
        },
      ],
    }).toDomain();

    expect(page.items, hasLength(1));
    final scene = page.items.first as TimelineSceneItem;
    expect(scene.scene.naturalEnglish, 'I really like the tree.');
    expect(scene.scene.keyChunks.first.phrase, 'really like');
    expect(scene.scene.correction?.suggestion, 'I really like the tree.');
    expect(scene.audio?.url, '/api/v1/audio/scene.mp3');
    expect(scene.audio?.isReady, isTrue);
  });
}
