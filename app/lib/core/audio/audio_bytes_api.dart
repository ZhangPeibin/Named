import 'package:dio/dio.dart';

import '../network/api_exception.dart';

abstract class AudioBytesApi {
  Future<List<int>> fetch(String url);
}

class RemoteAudioBytesApi implements AudioBytesApi {
  const RemoteAudioBytesApi(this._dio);

  final Dio _dio;

  @override
  Future<List<int>> fetch(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Audio response was empty',
        );
      }
      return data;
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}
