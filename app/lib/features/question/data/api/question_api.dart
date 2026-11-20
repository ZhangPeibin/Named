import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/question.dart';
import '../dto/question_dto.dart';

abstract class QuestionApi {
  Future<QuestionThreadDto> ask(String text, {QuestionContext? context});

  Future<List<QuestionThreadSummaryDto>> fetchThreads();

  Future<QuestionThreadDto> fetchThread(String threadId);

  Future<QuestionThreadDto> followUp(String threadId, String text);

  Future<void> deleteThread(String threadId);

  Future<QuestionMessageDto> setFeedback({
    required String threadId,
    required String messageId,
    required String feedback,
  });
}

class RemoteQuestionApi implements QuestionApi {
  const RemoteQuestionApi(this._dio);

  final Dio _dio;

  @override
  Future<QuestionThreadDto> ask(String text, {QuestionContext? context}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/questions',
        data: {'text': text, if (context != null) 'context': context.toJson()},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Question response was empty',
        );
      }
      return QuestionThreadDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<QuestionThreadSummaryDto>> fetchThreads() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/questions',
      );
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(QuestionThreadSummaryDto.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<QuestionThreadDto> fetchThread(String threadId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/questions/$threadId',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Question thread response was empty',
        );
      }
      return QuestionThreadDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<QuestionThreadDto> followUp(String threadId, String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/questions/$threadId/messages',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Question follow-up response was empty',
        );
      }
      return QuestionThreadDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> deleteThread(String threadId) async {
    try {
      await _dio.delete<void>('/api/v1/questions/$threadId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<QuestionMessageDto> setFeedback({
    required String threadId,
    required String messageId,
    required String feedback,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/questions/$threadId/messages/$messageId/feedback',
        data: {'feedback': feedback},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Question feedback response was empty',
        );
      }
      return QuestionMessageDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final apiException = error.error;
    if (apiException is ApiException) {
      return apiException;
    }
    return ApiException.fromDioException(error);
  }
}

class MockQuestionApi implements QuestionApi {
  MockQuestionApi();

  final _threads = <QuestionThreadDto>[];

  @override
  Future<QuestionThreadDto> ask(String text, {QuestionContext? context}) async {
    final now = DateTime.now();
    final thread = QuestionThreadDto(
      id: 'mock-question-${_threads.length + 1}',
      title: text,
      contextType: context?.type,
      contextRef: context?.ref,
      contextQuote: context?.quote,
      createdAt: now,
      updatedAt: now,
      messages: [
        QuestionMessageDto(
          id: 'mock-user-${_threads.length + 1}',
          role: 'user',
          text: text,
          example: null,
          nativeExplanation: null,
          confidence: null,
          followUpSuggestions: const [],
          feedback: null,
          createdAt: now,
        ),
        QuestionMessageDto(
          id: 'mock-assistant-${_threads.length + 1}',
          role: 'assistant',
          text: 'A simple answer to your question.',
          example: 'Here is a short example.',
          nativeExplanation: '这是这个问题的中文解释。',
          confidence: 'high',
          followUpSuggestions: const [
            'Could I use will instead?',
            'Show me another example.',
          ],
          feedback: null,
          createdAt: now,
        ),
      ],
    );
    _threads.add(thread);
    return thread;
  }

  @override
  Future<List<QuestionThreadSummaryDto>> fetchThreads() async {
    return _threads.reversed.map((thread) {
      return QuestionThreadSummaryDto(
        id: thread.id,
        title: thread.title,
        contextType: thread.contextType,
        contextQuote: thread.contextQuote,
        lastText: thread.messages.last.text,
        updatedAt: thread.updatedAt,
      );
    }).toList();
  }

  @override
  Future<QuestionThreadDto> fetchThread(String threadId) async {
    return _threads.firstWhere((thread) => thread.id == threadId);
  }

  @override
  Future<QuestionThreadDto> followUp(String threadId, String text) async {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    final current = _threads[index];
    final now = DateTime.now();
    final next = QuestionThreadDto(
      id: current.id,
      title: current.title,
      contextType: current.contextType,
      contextRef: current.contextRef,
      contextQuote: current.contextQuote,
      createdAt: current.createdAt,
      updatedAt: now,
      messages: [
        ...current.messages,
        QuestionMessageDto(
          id: 'mock-user-follow-${current.messages.length}',
          role: 'user',
          text: text,
          example: null,
          nativeExplanation: null,
          confidence: null,
          followUpSuggestions: const [],
          feedback: null,
          createdAt: now,
        ),
        QuestionMessageDto(
          id: 'mock-assistant-follow-${current.messages.length}',
          role: 'assistant',
          text: 'A follow-up answer.',
          example: 'Another short example.',
          nativeExplanation: '这是追问后的中文解释。',
          confidence: 'high',
          followUpSuggestions: const [],
          feedback: null,
          createdAt: now,
        ),
      ],
    );
    _threads[index] = next;
    return next;
  }

  @override
  Future<void> deleteThread(String threadId) async {
    _threads.removeWhere((thread) => thread.id == threadId);
  }

  @override
  Future<QuestionMessageDto> setFeedback({
    required String threadId,
    required String messageId,
    required String feedback,
  }) async {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    final current = _threads[index];
    QuestionMessageDto? updated;
    final messages = current.messages.map((message) {
      if (message.id != messageId) {
        return message;
      }
      updated = QuestionMessageDto(
        id: message.id,
        role: message.role,
        text: message.text,
        example: message.example,
        nativeExplanation: message.nativeExplanation,
        confidence: message.confidence,
        followUpSuggestions: message.followUpSuggestions,
        feedback: feedback,
        createdAt: message.createdAt,
      );
      return updated!;
    }).toList();
    _threads[index] = QuestionThreadDto(
      id: current.id,
      title: current.title,
      contextType: current.contextType,
      contextRef: current.contextRef,
      contextQuote: current.contextQuote,
      messages: messages,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    return updated ??
        (throw const ApiException(
          type: ApiExceptionType.notFound,
          message: 'Question message not found',
        ));
  }
}
