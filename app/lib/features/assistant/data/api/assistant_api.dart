import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/assistant_intent_dto.dart';

abstract class AssistantApi {
  Future<AssistantIntentDto> route(String text);
}

class RemoteAssistantApi implements AssistantApi {
  const RemoteAssistantApi(this._dio);

  final Dio _dio;

  @override
  Future<AssistantIntentDto> route(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/assistant/route',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Assistant response was empty',
        );
      }
      return AssistantIntentDto.fromJson(data);
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

class MockAssistantApi implements AssistantApi {
  const MockAssistantApi();

  @override
  Future<AssistantIntentDto> route(String text) async {
    return const AssistantIntentDto(intent: 'none', confidence: 1);
  }
}
