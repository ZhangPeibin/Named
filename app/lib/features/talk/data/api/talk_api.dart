import 'dart:typed_data';

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

  Future<HelpSuggestionDto> helpExpression({
    required String conversationId,
    required String text,
  });

  Future<PronunciationAudioDto> synthesizePronunciation(String text);

  Future<String> transcribeAudio(Uint8List audio);

  Future<TalkAudioDto> synthesizeSpeech(String text);
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
  Future<HelpSuggestionDto> helpExpression({
    required String conversationId,
    required String text,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId/help',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Help response was empty',
        );
      }
      return HelpSuggestionDto.fromJson(data);
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

  @override
  Future<PronunciationAudioDto> synthesizePronunciation(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/pronunciation',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Pronunciation response was empty',
        );
      }
      return PronunciationAudioDto.fromJson(data);
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

  @override
  Future<String> transcribeAudio(Uint8List audio) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(audio, filename: 'voice.wav'),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/transcribe',
        data: form,
      );
      final data = response.data;
      if (data == null || data['text'] is! String) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Transcription response was empty',
        );
      }
      return data['text'] as String;
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<TalkAudioDto> synthesizeSpeech(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/speech',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Speech response was empty',
        );
      }
      return TalkAudioDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
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

  @override
  Future<PronunciationAudioDto> synthesizePronunciation(String text) async {
    return const PronunciationAudioDto(usUrl: null, ukUrl: null);
  }

  @override
  Future<String> transcribeAudio(Uint8List audio) async {
    return 'This is a mock voice transcript.';
  }

  @override
  Future<TalkAudioDto> synthesizeSpeech(String text) async {
    return const TalkAudioDto(url: null, status: 'unavailable');
  }

  @override
  Future<HelpSuggestionDto> helpExpression({
    required String conversationId,
    required String text,
  }) async {
    return const HelpSuggestionDto(
      naturalEnglish: 'This tree is beautiful.',
      note: '可以这样说。',
      alternatives: ['The tree is beautiful.'],
      audio: null,
    );
  }

  ConversationDto _conversation(String id, String focusType, String focusId) {
    return ConversationDto(
      id: id,
      title: focusType == 'scene' ? 'A moment from my day' : 'tree',
      focusType: focusType,
      focusId: focusId,
      status: 'active',
      messages: List<TalkMessageDto>.unmodifiable(_messages[id] ?? const []),
    );
  }
}
