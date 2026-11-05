import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/app_version_check_dto.dart';

class AppVersionApi {
  const AppVersionApi(this._dio, {required this.checkPath});

  final Dio _dio;
  final String checkPath;

  Future<AppVersionCheckDto> checkVersion({
    required String platform,
    required String version,
    required int build,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        checkPath,
        queryParameters: {
          'platform': platform,
          'version': version,
          'build': build,
        },
      );
      return AppVersionCheckDto.fromJson(unwrapApiData(response));
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}
