import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/timeline_dto.dart';

abstract class TimelineApi {
  Future<TimelineResponseDto> fetch({
    int limit = 30,
    String? before,
    String? type,
  });
}

class RemoteTimelineApi implements TimelineApi {
  const RemoteTimelineApi(this._dio);

  final Dio _dio;

  @override
  Future<TimelineResponseDto> fetch({
    int limit = 30,
    String? before,
    String? type,
  }) async {
    try {
      final query = <String, dynamic>{'limit': limit};
      if (before != null) {
        query['before'] = before;
      }
      if (type != null) {
        query['type'] = type;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/timeline',
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Timeline response was empty',
        );
      }
      return TimelineResponseDto.fromJson(data);
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

class MockTimelineApi implements TimelineApi {
  const MockTimelineApi();

  @override
  Future<TimelineResponseDto> fetch({
    int limit = 30,
    String? before,
    String? type,
  }) async {
    return const TimelineResponseDto(items: [], nextCursor: null);
  }
}
