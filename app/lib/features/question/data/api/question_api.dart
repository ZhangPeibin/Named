import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/question_dto.dart';

abstract class QuestionApi {
  Future<QuestionDto> ask(String text);
  Future<List<QuestionDto>> fetchHistory();
}

class RemoteQuestionApi implements QuestionApi {
  const RemoteQuestionApi(this._dio);

  final Dio _dio;

  @override
  Future<QuestionDto> ask(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/questions',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Question response was empty',
        );
      }
      return QuestionDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<List<QuestionDto>> fetchHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/questions',
      );
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(QuestionDto.fromJson)
          .toList();
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}

class MockQuestionApi implements QuestionApi {
  MockQuestionApi();

  final _items = <QuestionDto>[];

  @override
  Future<QuestionDto> ask(String text) async {
    final item = QuestionDto(
      id: 'mock-question-${_items.length + 1}',
      question: text,
      answer: 'A simple answer to your question.',
      nativeExplanation: '这是这个问题的中文解释。',
      createdAt: DateTime.now(),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<List<QuestionDto>> fetchHistory() async {
    return _items.reversed.toList();
  }
}
