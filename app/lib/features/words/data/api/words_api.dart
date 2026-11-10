import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/word_shelf_dto.dart';

abstract class WordsApi {
  Future<WordShelfDto> fetch();

  Future<void> setKnown({required String wordId, required bool known});

  Future<void> markReviewed(String wordId);

  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
  });
}

class RemoteWordsApi implements WordsApi {
  const RemoteWordsApi(this._dio);

  final Dio _dio;

  @override
  Future<WordShelfDto> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/words');
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Words response was empty',
        );
      }
      return WordShelfDto.fromJson(data);
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
  Future<void> setKnown({required String wordId, required bool known}) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/v1/words/$wordId/progress',
        data: {'known': known},
      ),
    );
  }

  @override
  Future<void> markReviewed(String wordId) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>('/api/v1/words/$wordId/reviewed'),
    );
  }

  @override
  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
  }) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/words/from-talk',
        data: {
          'label': label,
          'meaning_zh': meaningZh,
          'part_of_speech': partOfSpeech,
          'grammar': grammar,
          'example_en': exampleEn,
        },
      ),
    );
  }

  Future<void> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      await request();
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}

class MockWordsApi implements WordsApi {
  @override
  Future<WordShelfDto> fetch() async {
    return const WordShelfDto(
      stats: WordsStatsDto(
        total: 0,
        newThisWeek: 0,
        reviewedThisWeek: 0,
        usedInTalkThisWeek: 0,
      ),
      words: [],
    );
  }

  @override
  Future<void> setKnown({required String wordId, required bool known}) async {}

  @override
  Future<void> markReviewed(String wordId) async {}

  @override
  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
  }) async {}
}
