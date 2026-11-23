import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../discover/data/dto/discover_dto.dart';
import '../../domain/practice_word.dart';
import '../dto/practice_word_dto.dart';

abstract class PracticeApi {
  Future<PracticeWordDto> next();

  Future<PracticeCompleteDto> complete(String wordId);

  Future<PracticeReplyDto> reply({
    required String wordId,
    required String text,
    required List<PracticeTurn> history,
  });
}

class RemotePracticeApi implements PracticeApi {
  const RemotePracticeApi(this._dio);

  final Dio _dio;

  @override
  Future<PracticeWordDto> next() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/practice/next',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Practice response was empty',
        );
      }
      return PracticeWordDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<PracticeCompleteDto> complete(String wordId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/practice/$wordId/complete',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Practice completion response was empty',
        );
      }
      return PracticeCompleteDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<PracticeReplyDto> reply({
    required String wordId,
    required String text,
    required List<PracticeTurn> history,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/practice/$wordId/reply',
        data: {
          'text': text,
          'history': history.map((turn) => turn.toJson()).toList(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Practice reply response was empty',
        );
      }
      return PracticeReplyDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}

class MockPracticeApi implements PracticeApi {
  const MockPracticeApi();

  @override
  Future<PracticeWordDto> next() async {
    return const PracticeWordDto(
      id: 'mock-practice-word',
      label: 'tree',
      word: DiscoveredWordDto(
        spelling: 'tree',
        ipa: {'us': '/triː/', 'uk': '/triː/'},
        pos: ['noun'],
        senses: [
          WordSenseDto(
            definitionEn: 'a tall plant with a trunk and branches',
            definitionZh: '有树干和树枝的高大植物',
            exampleEn: 'There is a tree in the park.',
            exampleZh: '公园里有一棵树。',
          ),
        ],
        grammar: '',
        related: [],
        chunks: [],
        varietyNotes: [],
        sceneExtensions: [],
      ),
      audio: null,
      context: '树',
      options: ['river', 'leaf'],
      practiceCount: 0,
    );
  }

  @override
  Future<PracticeCompleteDto> complete(String wordId) async {
    return PracticeCompleteDto(wordId: wordId, practiceCount: 1);
  }

  @override
  Future<PracticeReplyDto> reply({
    required String wordId,
    required String text,
    required List<PracticeTurn> history,
  }) async {
    return const PracticeReplyDto(
      reply: 'That sounds nice. How often do you see it?',
      recast: 'I saw a tree in the park yesterday.',
      nativeReply: null,
    );
  }
}
