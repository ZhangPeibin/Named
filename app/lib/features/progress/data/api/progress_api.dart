import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/progress_dto.dart';

abstract class ProgressApi {
  Future<ProgressDto> fetch();
}

class RemoteProgressApi implements ProgressApi {
  const RemoteProgressApi(this._dio);

  final Dio _dio;

  @override
  Future<ProgressDto> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/progress');
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Progress response was empty',
        );
      }
      return ProgressDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}

class MockProgressApi implements ProgressApi {
  const MockProgressApi();

  @override
  Future<ProgressDto> fetch() async {
    return const ProgressDto(words: 500, conversations: 300, readings: 100);
  }
}
