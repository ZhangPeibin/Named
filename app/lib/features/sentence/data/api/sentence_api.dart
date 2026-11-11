import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/sentence_dto.dart';

abstract class SentenceApi {
  Future<SentenceDetailDto> lookup(String text);
}

class RemoteSentenceApi implements SentenceApi {
  const RemoteSentenceApi(this._dio);

  final Dio _dio;

  @override
  Future<SentenceDetailDto> lookup(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sentences/lookup',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Sentence response was empty',
        );
      }
      return SentenceDetailDto.fromJson(data);
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

class MockSentenceApi implements SentenceApi {
  @override
  Future<SentenceDetailDto> lookup(String text) async {
    return const SentenceDetailDto(
      original: '我今天很开心',
      naturalEnglish: 'I am happy today.',
      explanationNative: '这是一句表达今天心情的话。',
      grammarNotes: '主语 + be 动词 + 形容词。',
      chunks: [SentenceChunkDto(phrase: 'be happy', meaningNative: '开心')],
      keyWords: [
        SentenceKeyWordDto(
          word: 'happy',
          partOfSpeech: 'adj.',
          meaningNative: '开心的',
        ),
      ],
    );
  }
}
