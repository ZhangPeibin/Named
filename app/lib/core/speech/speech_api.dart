import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import 'speech_audio.dart';

/// Speech input and output shared by every feature. Owns the `/audio/*`
/// endpoints so features never construct ad-hoc STT/TTS requests.
abstract class SpeechApi {
  Future<String> transcribe(Uint8List wav);

  Future<SpeechClip> synthesize(String text);

  Future<PronunciationAudio> pronounce(String text);
}

class RemoteSpeechApi implements SpeechApi {
  const RemoteSpeechApi(this._dio);

  final Dio _dio;

  @override
  Future<String> transcribe(Uint8List wav) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(wav, filename: 'voice.wav'),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/transcribe',
        data: form,
      );
      final data = response.data;
      if (data == null || data['text'] is! String) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Transcription response was empty',
        );
      }
      return data['text'] as String;
    } on DioException catch (error) {
      throw _asApiException(error);
    }
  }

  @override
  Future<SpeechClip> synthesize(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/speech',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Speech response was empty',
        );
      }
      return SpeechClip(
        url: data['url'] as String?,
        status: data['status'] as String? ?? 'unavailable',
      );
    } on DioException catch (error) {
      throw _asApiException(error);
    }
  }

  @override
  Future<PronunciationAudio> pronounce(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/audio/pronunciation',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Pronunciation response was empty',
        );
      }
      final us = data['us'];
      final uk = data['uk'];
      return PronunciationAudio(
        usUrl: us is Map<String, dynamic> ? us['url'] as String? : null,
        ukUrl: uk is Map<String, dynamic> ? uk['url'] as String? : null,
      );
    } on DioException catch (error) {
      throw _asApiException(error);
    }
  }

  ApiException _asApiException(DioException error) {
    final apiException = error.error;
    if (apiException is ApiException) {
      return apiException;
    }
    return ApiException.fromDioException(error);
  }
}

class MockSpeechApi implements SpeechApi {
  const MockSpeechApi();

  @override
  Future<PronunciationAudio> pronounce(String text) async {
    return const PronunciationAudio(usUrl: null, ukUrl: null);
  }

  @override
  Future<SpeechClip> synthesize(String text) async {
    return const SpeechClip(url: null, status: 'unavailable');
  }

  @override
  Future<String> transcribe(Uint8List wav) async {
    return 'This is a mock voice transcript.';
  }
}
