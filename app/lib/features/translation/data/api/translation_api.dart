import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/translation_dto.dart';

abstract class TranslationApi {
  Future<TranslationDto> translate(String text);
}

class RemoteTranslationApi implements TranslationApi {
  const RemoteTranslationApi(this._dio);

  final Dio _dio;

  @override
  Future<TranslationDto> translate(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/translate',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Translation response was empty',
        );
      }
      return TranslationDto.fromJson(data);
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

class MockTranslationApi implements TranslationApi {
  @override
  Future<TranslationDto> translate(String text) async {
    final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    return TranslationDto(
      sourceLanguage: isChinese ? 'zh' : 'en',
      targetLanguage: isChinese ? 'en' : 'zh',
      translatedText: isChinese ? 'tree' : '树',
    );
  }
}
