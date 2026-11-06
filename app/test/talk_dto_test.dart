import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/talk/data/dto/talk_dto.dart';

void main() {
  test('parses a conversation with corrections and annotations', () {
    final conversation = ConversationDto.fromJson({
      'id': 'conversation-1',
      'title': 'tree',
      'focus_type': 'word',
      'focus_id': 'word-1',
      'status': 'active',
      'started_at': '2026-11-05T10:00:00Z',
      'ended_at': null,
      'messages': [
        {
          'id': 'message-1',
          'role': 'assistant',
          'text': 'What did you notice?',
          'native_text': '你注意到了什么？',
          'source': 'text',
          'transcript_state': 'confirmed',
          'status': 'saved',
          'corrections': <Object?>[],
          'annotations': [
            {
              'id': 'annotation-1',
              'text': 'notice',
              'kind': 'word',
              'meaning_zh': '注意到',
            },
          ],
          'audio': {
            'url': 'https://api.test/media/reply.mp3',
            'status': 'ready',
          },
          'created_at': '2026-11-05T10:00:01Z',
        },
      ],
    }).toDomain();

    expect(conversation.id, 'conversation-1');
    expect(conversation.title, 'tree');
    expect(conversation.messages, hasLength(1));
    expect(conversation.messages.first.nativeText, '你注意到了什么？');
    expect(conversation.messages.first.annotations.first.meaningZh, '注意到');
    expect(conversation.messages.first.audio?.isReady, isTrue);
    expect(
      conversation.messages.first.audio?.url,
      'https://api.test/media/reply.mp3',
    );
  });

  test('parses a turn with user and assistant messages', () {
    final turn = TurnDto.fromJson({
      'user_message': {
        'id': 'message-2',
        'role': 'user',
        'text': 'I saw a flower.',
        'corrections': <Object?>[],
        'annotations': <Object?>[],
      },
      'assistant_message': {
        'id': 'message-3',
        'role': 'assistant',
        'text': 'That sounds lovely.',
        'corrections': [
          {
            'id': 'correction-1',
            'original': 'I saw a flower.',
            'suggestion': 'I saw a flower today.',
            'note': 'Add a time word for context.',
          },
        ],
        'annotations': <Object?>[],
      },
      'save_status': 'saved',
    }).toDomain();

    expect(turn.userMessage.text, 'I saw a flower.');
    expect(turn.assistantMessage.text, 'That sounds lovely.');
    expect(
      turn.assistantMessage.corrections.first.suggestion,
      'I saw a flower today.',
    );
  });
}
