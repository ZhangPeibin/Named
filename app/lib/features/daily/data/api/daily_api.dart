import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/daily_read.dart';
import '../dto/daily_read_dto.dart';
import '../dto/daily_translation_dto.dart';

abstract class DailyApi {
  Future<DailyReadDto> fetchToday({DateTime? date});

  Future<DailyTranslationDto> fetchTranslation({DateTime? date});

  Future<DailyCompletionDto> complete({int? durationSeconds});
}

class RemoteDailyApi implements DailyApi {
  const RemoteDailyApi(this._dio);

  final Dio _dio;

  @override
  Future<DailyReadDto> fetchToday({DateTime? date}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/daily/read',
        queryParameters: date == null ? null : {'date': _dateKey(date)},
        // The first read of a day is generated on demand (text + audio) and
        // regularly exceeds the 10s default.
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Daily reading response was empty',
        );
      }
      return DailyReadDto.fromJson(data);
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
  Future<DailyTranslationDto> fetchTranslation({DateTime? date}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/daily/read/translation',
        queryParameters: date == null ? null : {'date': _dateKey(date)},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Daily translation response was empty',
        );
      }
      return DailyTranslationDto.fromJson(data);
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
  Future<DailyCompletionDto> complete({int? durationSeconds}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/daily/read/complete',
        data: {'duration_seconds': durationSeconds},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Daily completion response was empty',
        );
      }
      return DailyCompletionDto.fromJson(data);
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

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class MockDailyApi implements DailyApi {
  const MockDailyApi();

  @override
  Future<DailyReadDto> fetchToday({DateTime? date}) async {
    return DailyReadDto(
      date: DateTime.now(),
      title: 'A Quiet Morning',
      passage:
          'Today I noticed a small thing near the window. I stopped to look at it and felt quiet. The light moved slowly across the floor.',
      targetWords: const ['notice', 'small', 'quiet'],
      question: 'What did you notice today?',
      audioUrl: null,
      words: const [],
    );
  }

  @override
  Future<DailyTranslationDto> fetchTranslation({DateTime? date}) async {
    return const DailyTranslationDto(
      language: 'zh',
      lines: [
        DailyTranslationLine(
          text: 'Today I noticed a small thing near the window.',
          startChar: 0,
          endChar: 46,
          translation: '今天我注意到窗边有一件小事。',
        ),
        DailyTranslationLine(
          text: 'I stopped to look at it and felt quiet.',
          startChar: 47,
          endChar: 86,
          translation: '我停下来看着它，感到很安静。',
        ),
        DailyTranslationLine(
          text: 'The light moved slowly across the floor.',
          startChar: 87,
          endChar: 127,
          translation: '光线慢慢在地板上移动。',
        ),
      ],
    );
  }

  @override
  Future<DailyCompletionDto> complete({int? durationSeconds}) async {
    return DailyCompletionDto(
      date: DateTime.now(),
      streak: 1,
      wordCount: 27,
      targetWords: const ['notice', 'small', 'quiet'],
      durationSeconds: durationSeconds,
    );
  }
}
