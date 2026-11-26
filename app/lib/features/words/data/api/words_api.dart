import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../discover/data/dto/discover_dto.dart';
import '../../domain/word_shelf.dart';
import '../dto/word_shelf_dto.dart';

abstract class WordsApi {
  Future<WordShelfDto> fetch();

  Future<WordShelfItemDto> lookup(String text, {String level = 'full'});

  Future<WordShelfItemDto> fetchDetails(String wordId);

  Future<bool> addToShelf(String wordId);

  Future<void> setKnown({required String wordId, required bool known});

  Future<void> markReviewed(String wordId);

  Future<void> markAttempt({required String wordId, required String text});

  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
    String? ipa,
    String? syllables,
    List<String> vowels,
    List<String> consonants,
    String? phonics,
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
  Future<WordShelfItemDto> lookup(String text, {String level = 'full'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/words/lookup',
        queryParameters: {'text': text, 'level': level},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Word lookup response was empty',
        );
      }
      return WordShelfItemDto.fromJson(data);
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
  Future<WordShelfItemDto> fetchDetails(String wordId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/words/$wordId/details',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Word details response was empty',
        );
      }
      return WordShelfItemDto.fromJson(data);
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
  Future<bool> addToShelf(String wordId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/words/$wordId/save',
      );
      return response.data?['created'] as bool? ?? true;
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
  Future<void> markAttempt({
    required String wordId,
    required String text,
  }) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/words/$wordId/attempt',
        data: {'attempted_text': text},
      ),
    );
  }

  @override
  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
    String? ipa,
    String? syllables,
    List<String> vowels = const [],
    List<String> consonants = const [],
    String? phonics,
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
          'ipa': ipa,
          'syllables': syllables,
          'vowels': vowels,
          'consonants': consonants,
          'phonics': phonics,
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
  Future<WordShelfItemDto> lookup(String text, {String level = 'full'}) async {
    return WordShelfItemDto(
      id: 'mock-lookup-word',
      label: text,
      word: DiscoveredWordDto(
        spelling: text,
        ipa: const {'us': '/wɜːrd/'},
        pos: const ['n.'],
        senses: const [
          WordSenseDto(
            definitionEn: 'A word selected from Talk.',
            definitionZh: '从对话中选中的词',
            exampleEn: 'This is the word.',
            exampleZh: '这就是这个词。',
          ),
        ],
        grammar: '',
        related: const [],
        chunks: const [],
        varietyNotes: const [],
        sceneExtensions: const [],
      ),
      audio: null,
      discoveryCount: 1,
      firstSeenAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      status: WordShelfStatus.needsReview,
      saved: false,
      contentLevel: level,
    );
  }

  @override
  Future<WordShelfItemDto> fetchDetails(String wordId) async {
    return WordShelfItemDto(
      id: wordId,
      label: 'mock',
      word: const DiscoveredWordDto(
        spelling: 'mock',
        ipa: {},
        pos: [],
        senses: [
          WordSenseDto(
            definitionEn: 'A full mock definition.',
            definitionZh: '完整的模拟释义。',
            exampleEn: 'A full mock example.',
            exampleZh: '完整的模拟例句。',
          ),
        ],
        grammar: 'mock grammar',
        related: [],
        chunks: [],
        varietyNotes: [],
        sceneExtensions: [],
      ),
      audio: null,
      discoveryCount: 1,
      firstSeenAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      status: WordShelfStatus.needsReview,
      saved: false,
      contentLevel: 'full',
    );
  }

  @override
  Future<WordShelfDto> fetch() async {
    return const WordShelfDto(
      stats: WordsStatsDto(total: 0, newThisWeek: 0, usedInTalkThisWeek: 0),
      words: [],
    );
  }

  @override
  Future<bool> addToShelf(String wordId) async {
    return true;
  }

  @override
  Future<void> setKnown({required String wordId, required bool known}) async {}

  @override
  Future<void> markReviewed(String wordId) async {}

  @override
  Future<void> markAttempt({
    required String wordId,
    required String text,
  }) async {}

  @override
  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
    String? ipa,
    String? syllables,
    List<String> vowels = const [],
    List<String> consonants = const [],
    String? phonics,
  }) async {}
}
