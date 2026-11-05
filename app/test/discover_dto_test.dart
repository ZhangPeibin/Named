import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/data/dto/discover_dto.dart';

void main() {
  test('parses a ready discovery with word content', () {
    final discovery = DiscoverDto.fromJson({
      'id': 'discovery-1',
      'input_type': 'text',
      'input_text': 'I noticed a small flower by the road.',
      'context': null,
      'input_language': 'en',
      'status': 'ready',
      'focus_kind': 'word',
      'word_id': 'word-1',
      'candidates': <Object?>[],
      'word': {
        'spelling': 'notice',
        'ipa': {'us': '/ˈnoʊtɪs/'},
        'pos': ['verb'],
        'senses': [
          {
            'definition_en': 'to see or become aware of something',
            'definition_zh': '注意到；察觉到',
            'example_en': 'I noticed a small flower.',
            'example_zh': '我注意到一朵小花。',
          },
        ],
        'grammar': 'notice / noticed / noticing',
        'related': ['observe', 'spot'],
        'chunks': [
          {
            'phrase': 'notice something',
            'meaning_zh': '注意到某事',
            'example_en': 'I noticed something small.',
          },
        ],
        'variety_notes': [
          {
            'kind': 'spelling',
            'description_zh': '美式和英式拼写相同。',
            'us': 'notice',
            'uk': 'notice',
            'example_en': 'Did you notice that?',
          },
        ],
        'scene_extensions': [
          {
            'label_en': 'attention',
            'label_zh': '注意力',
            'relationship': 'what noticing requires',
          },
        ],
      },
      'needs_confirmation': false,
      'warnings': <Object?>[],
    }).toDomain();

    expect(discovery.id, 'discovery-1');
    expect(discovery.isReady, isTrue);
    expect(discovery.word?.spelling, 'notice');
    expect(discovery.word?.primarySense?.definitionZh, '注意到；察觉到');
    expect(discovery.wordId, 'word-1');
    expect(discovery.word?.chunks.first.phrase, 'notice something');
    expect(discovery.word?.varietyNotes.first.kind, 'spelling');
    expect(discovery.word?.sceneExtensions.first.labelZh, '注意力');
  });

  test('parses a discovery that needs confirmation', () {
    final discovery = DiscoverDto.fromJson({
      'id': 'discovery-2',
      'input_type': 'text',
      'input_text': 'notice',
      'context': null,
      'input_language': 'en',
      'status': 'needs_confirmation',
      'focus_kind': null,
      'word_id': null,
      'candidates': [
        {
          'id': 'candidate-1',
          'label_en': 'notice',
          'label_zh': '注意到',
          'confidence': 0.92,
          'reason': 'Most likely the verb.',
          'selected': false,
        },
      ],
      'word': null,
      'needs_confirmation': true,
      'warnings': <Object?>[],
    }).toDomain();

    expect(discovery.needsConfirmation, isTrue);
    expect(discovery.candidates, hasLength(1));
    expect(discovery.candidates.first.labelZh, '注意到');
    expect(discovery.word, isNull);
  });
}
