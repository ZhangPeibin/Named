import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/soul_dto.dart';

abstract class SoulApi {
  Future<SoulDto> fetchSoul();

  Future<SoulDto> updateSoul({
    required String nativeLanguage,
    int? age,
    String? gender,
  });
}

class RemoteSoulApi implements SoulApi {
  const RemoteSoulApi(this._dio);

  final Dio _dio;

  @override
  Future<SoulDto> fetchSoul() async {
    return _guard(() => _dio.get<Map<String, dynamic>>('/api/v1/soul'));
  }

  @override
  Future<SoulDto> updateSoul({
    required String nativeLanguage,
    int? age,
    String? gender,
  }) async {
    return _guard(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/v1/soul',
        data: {'native_language': nativeLanguage, 'age': age, 'gender': gender},
      ),
    );
  }

  Future<SoulDto> _guard(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Soul response was empty',
        );
      }
      return SoulDto.fromJson(data);
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
