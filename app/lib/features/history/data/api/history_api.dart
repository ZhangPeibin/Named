import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/history_experience.dart';
import '../dto/history_dto.dart';

abstract class HistoryApi {
  Future<HistoryPageDto> fetch({String? before});
  Future<HistoryExperienceDto> fetchExperience(String id);
}

class RemoteHistoryApi implements HistoryApi {
  const RemoteHistoryApi(this._dio);

  final Dio _dio;

  @override
  Future<HistoryPageDto> fetch({String? before}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/history',
        queryParameters: before == null ? null : {'before': before},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'History response was empty',
        );
      }
      return HistoryPageDto.fromJson(data);
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
  Future<HistoryExperienceDto> fetchExperience(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/experiences/$id',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Experience response was empty',
        );
      }
      return HistoryExperienceDto.fromJson(data);
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

class MockHistoryApi implements HistoryApi {
  @override
  Future<HistoryPageDto> fetch({String? before}) async {
    return HistoryPageDto(
      items: [
        HistoryExperienceDto(
          id: 'mock-life',
          kind: ExperienceKind.life,
          summary: '和女儿在公园的树荫下休息。',
          confidence: 0.9,
          createdAt: DateTime.now(),
          focusType: 'word',
          focusId: 'mock-word',
          focusTitle: 'tree',
          conversationId: 'mock-conversation',
        ),
        HistoryExperienceDto(
          id: 'mock-learning',
          kind: ExperienceKind.learning,
          summary: '练习了 under the tree。',
          confidence: 0.8,
          createdAt: DateTime.now(),
          focusType: 'word',
          focusId: 'mock-word',
          focusTitle: 'tree',
          conversationId: 'mock-conversation',
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<HistoryExperienceDto> fetchExperience(String id) async {
    return HistoryExperienceDto(
      id: id,
      kind: id.contains('learning')
          ? ExperienceKind.learning
          : ExperienceKind.life,
      summary: id.contains('learning')
          ? '练习了 under the tree。'
          : '和女儿在公园的树荫下休息。',
      confidence: 0.9,
      createdAt: DateTime.now(),
      focusType: 'word',
      focusId: 'mock-word',
      focusTitle: 'tree',
      conversationId: 'mock-conversation',
      sources: [
        const ExperienceSourceDto(
          type: 'message',
          id: 'mock-message',
          quote: '今天在公园看到一棵树。',
        ),
        const ExperienceSourceDto(type: 'expression', id: 'under the tree'),
      ],
    );
  }
}
