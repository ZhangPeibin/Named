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

  Future<SoulItemDto> createItem({required String kind, required String text});

  Future<SoulItemDto> updateItem({
    required String id,
    required String kind,
    required String text,
  });

  Future<void> deleteItem(String id);
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

  @override
  Future<SoulItemDto> createItem({
    required String kind,
    required String text,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/soul/items',
        data: {'kind': kind, 'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Soul item response was empty',
        );
      }
      return SoulItemDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<SoulItemDto> updateItem({
    required String id,
    required String kind,
    required String text,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/soul/items/$id',
        data: {'kind': kind, 'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Soul item response was empty',
        );
      }
      return SoulItemDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete<void>('/api/v1/soul/items/$id');
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
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
