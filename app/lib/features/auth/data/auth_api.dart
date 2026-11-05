import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import '../domain/initial_soul.dart';
import 'dto/auth_code_dto.dart';
import 'dto/auth_session_dto.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<AuthCodeDto> requestCode(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/code',
        data: {'email': email},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Empty auth code response',
        );
      }
      return AuthCodeDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.badResponse,
        message: error.message,
      );
    }
  }

  Future<AuthSession> verify({
    required String email,
    required String code,
    InitialSoul? initialSoul,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/verify',
        data: {
          'email': email,
          'code': code,
          if (initialSoul != null) 'initial_soul': initialSoul.toJson(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Empty auth verify response',
        );
      }
      final dto = AuthSessionDto.fromJson(data);
      return AuthSession(token: dto.sessionToken, isNew: dto.isNew);
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.badResponse,
        message: error.message,
      );
    }
  }

  ApiException _mapError(DioException error) {
    final mapped = error.error;
    if (mapped is ApiException) {
      return mapped;
    }
    return ApiException.fromDioException(error);
  }
}
