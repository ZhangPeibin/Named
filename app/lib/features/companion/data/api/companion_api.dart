import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/companion_profile.dart';
import '../dto/companion_dto.dart';

const companionRandomNames = <String>[
  'Momo',
  'Miso',
  'Tofu',
  'Bao',
  'Bean',
  'Mochi',
  'Yuzu',
  'Sesame',
  'Moss',
  'Clover',
  'Pebble',
  'Sprout',
  'Poppy',
  'Sora',
  'Pip',
  'Nori',
  'Kiki',
  'Lulu',
  'Pepper',
  'Button',
];

abstract class CompanionApi {
  Future<CompanionProfileDto> fetchCompanion();

  Future<CompanionProfileDto> updateCompanion(Map<String, dynamic> changes);

  Future<String> suggestName();

  Future<CompanionProfileDto> assignRandomName();
}

class RemoteCompanionApi implements CompanionApi {
  const RemoteCompanionApi(this._dio);

  final Dio _dio;

  @override
  Future<CompanionProfileDto> fetchCompanion() {
    return _guard(() => _dio.get<Map<String, dynamic>>('/api/v1/companion'));
  }

  @override
  Future<CompanionProfileDto> updateCompanion(Map<String, dynamic> changes) {
    return _guard(
      () =>
          _dio.patch<Map<String, dynamic>>('/api/v1/companion', data: changes),
    );
  }

  @override
  Future<String> suggestName() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/companion/name-suggestion',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Companion name response was empty',
        );
      }
      return CompanionNameSuggestionDto.fromJson(data).name;
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
  Future<CompanionProfileDto> assignRandomName() {
    return _guard(
      () => _dio.post<Map<String, dynamic>>('/api/v1/companion/random-name'),
    );
  }

  Future<CompanionProfileDto> _guard(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Companion response was empty',
        );
      }
      return CompanionProfileDto.fromJson(data);
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

class MockCompanionApi implements CompanionApi {
  MockCompanionApi({String? name}) : _name = name;

  String? _name;
  String? _gender;
  String? _hobby;
  bool _setupDismissed = false;
  int _seed = 0;

  @override
  Future<CompanionProfileDto> fetchCompanion() async {
    return _dto();
  }

  @override
  Future<CompanionProfileDto> updateCompanion(
    Map<String, dynamic> changes,
  ) async {
    if (changes.containsKey('name')) {
      _name = changes['name'] as String?;
    }
    if (changes.containsKey('gender')) {
      _gender = changes['gender'] as String?;
    }
    if (changes.containsKey('hobby')) {
      _hobby = changes['hobby'] as String?;
    }
    if (changes.containsKey('setup_dismissed')) {
      _setupDismissed = changes['setup_dismissed'] as bool? ?? false;
    }
    return _dto();
  }

  @override
  Future<String> suggestName() async {
    return _nextName();
  }

  @override
  Future<CompanionProfileDto> assignRandomName() async {
    _name = _nextName();
    return _dto();
  }

  String _nextName() {
    final name = companionRandomNames[_seed % companionRandomNames.length];
    _seed += 1;
    return name;
  }

  CompanionProfileDto _dto() {
    return CompanionProfileDto(
      name: _name,
      gender: CompanionGender.fromWire(_gender),
      hobby: _hobby,
      avatarKey: 'companion_chill',
      voiceKey: 'companion_default',
      setupDismissed: _setupDismissed,
    );
  }
}
