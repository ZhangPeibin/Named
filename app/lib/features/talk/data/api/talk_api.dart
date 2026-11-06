import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/talk_dto.dart';

abstract class TalkApi {
  Future<ConversationDto> createConversation({
    required String focusType,
    required String focusId,
  });

  Future<ConversationDto> fetch(String conversationId);

  Future<TurnDto> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  });
}

class RemoteTalkApi implements TalkApi {
  const RemoteTalkApi(this._dio);

  final Dio _dio;

  @override
  Future<ConversationDto> createConversation({
    required String focusType,
    required String focusId,
  }) async {
    return _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/conversations',
        data: {'focus_type': focusType, 'focus_id': focusId},
      ),
    );
  }

  @override
  Future<ConversationDto> fetch(String conversationId) async {
    return _guard(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId',
      ),
    );
  }

  @override
  Future<TurnDto> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId/messages',
        data: {
          'client_message_id': clientMessageId,
          'text': text,
          'source': 'text',
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Talk response was empty',
        );
      }
      return TurnDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.badResponse,
        message: error.message,
      );
    }
  }

  Future<ConversationDto> _guard(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Talk response was empty',
        );
      }
      return ConversationDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.badResponse,
        message: error.message,
      );
    }
  }
}

class MockTalkApi implements TalkApi {
  MockTalkApi();

  final Map<String, List<TalkMessageDto>> _messages = {};
  var _nextConversation = 1;
  var _nextMessage = 1;

  @override
  Future<ConversationDto> createConversation({
    required String focusType,
    required String focusId,
  }) async {
    final id = 'mock-conversation-${_nextConversation++}';
    _messages[id] = [];
    return _conversation(id, focusType, focusId);
  }

  @override
  Future<ConversationDto> fetch(String conversationId) async {
    return _conversation(conversationId, 'word', 'mock-word');
  }

  @override
  Future<TurnDto> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    final user = TalkMessageDto(
      id: 'mock-message-${_nextMessage++}',
      role: 'user',
      text: text,
      corrections: const [
        MessageCorrectionDto(
          original: 'I saw a tree.',
          suggestion: 'I saw a tree today.',
          note: '加一个时间词会更自然。',
        ),
      ],
      annotations: const [],
    );
    final assistant = TalkMessageDto(
      id: 'mock-message-${_nextMessage++}',
      role: 'assistant',
      text: 'That sounds like a small, real moment. What did you notice first?',
      nativeText: '那听起来像一个真实的小瞬间。你最先注意到了什么？',
      corrections: const [],
      annotations: const [
        MessageAnnotationDto(
          text: 'notice',
          kind: 'word',
          meaningZh: '注意到；察觉到',
        ),
      ],
    );
    _messages.putIfAbsent(conversationId, () => []).addAll([user, assistant]);
    return TurnDto(userMessage: user, assistantMessage: assistant);
  }

  ConversationDto _conversation(String id, String focusType, String focusId) {
    return ConversationDto(
      id: id,
      title: 'tree',
      focusType: focusType,
      focusId: focusId,
      status: 'active',
      messages: List<TalkMessageDto>.unmodifiable(_messages[id] ?? const []),
    );
  }
}
