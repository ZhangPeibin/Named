import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';

abstract class TodoApi {
  Future<Map<String, dynamic>> fetchTodo(int id);
}

class RemoteTodoApi implements TodoApi {
  const RemoteTodoApi(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchTodo(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/todos/$id');
      final data = response.data;

      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Todo response was empty',
        );
      }

      return data;
    } on DioException catch (error) {
      final apiException = error.error;

      if (apiException is ApiException) {
        throw apiException;
      }

      throw ApiException.fromDioException(error);
    }
  }
}

/// Local mock used when [AppConfig.useMockApi] is true.
///
/// - `id == 0` → empty payload (demo empty state)
/// - `id < 0` → network failure (also hits Dio so global toast can fire)
/// - otherwise → sample success payload
class MockTodoApi implements TodoApi {
  const MockTodoApi(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchTodo(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (id == 0) {
      return const <String, dynamic>{};
    }

    if (id < 0) {
      try {
        await _dio.get<void>('https://invalid.invalid/todos/$id');
      } on DioException catch (error) {
        final apiException = error.error;
        if (apiException is ApiException) {
          throw apiException;
        }
        throw ApiException.fromDioException(error);
      }
    }

    return {
      'userId': 1,
      'id': id,
      'title': 'Mock todo from USE_MOCK_API',
      'completed': false,
    };
  }
}
