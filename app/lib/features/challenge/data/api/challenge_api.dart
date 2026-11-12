import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/challenge.dart';
import '../dto/challenge_dto.dart';

abstract class ChallengeApi {
  Future<List<ChallengeDto>> fetch();
  Future<ChallengeDto> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  });
  Future<ChallengeDto> fetchById(String id);
  Future<ChallengeDto> markVisited(String challengeId, String itemId);
  Future<ChallengeDto> end(String id);
}

class RemoteChallengeApi implements ChallengeApi {
  const RemoteChallengeApi(this._dio);

  final Dio _dio;

  @override
  Future<List<ChallengeDto>> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/challenges',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Challenge response was empty',
        );
      }
      return (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChallengeDto.fromJson)
          .toList();
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<ChallengeDto> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  }) async {
    return _challenge(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/challenges',
        data: {
          'name': name,
          'planned_days': plannedDays,
          'discovery_ids': discoveryIds,
        },
      ),
    );
  }

  @override
  Future<ChallengeDto> fetchById(String id) async {
    return _challenge(
      () => _dio.get<Map<String, dynamic>>('/api/v1/challenges/$id'),
    );
  }

  @override
  Future<ChallengeDto> markVisited(String challengeId, String itemId) async {
    return _challenge(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/challenges/$challengeId/items/$itemId/visited',
      ),
    );
  }

  @override
  Future<ChallengeDto> end(String id) async {
    return _challenge(
      () => _dio.post<Map<String, dynamic>>('/api/v1/challenges/$id/end'),
    );
  }

  Future<ChallengeDto> _challenge(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Challenge response was empty',
        );
      }
      return ChallengeDto.fromJson(data);
    } on DioException catch (error) {
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}

class MockChallengeApi implements ChallengeApi {
  final _challenges = <ChallengeDto>[];

  @override
  Future<List<ChallengeDto>> fetch() async => List.unmodifiable(_challenges);

  @override
  Future<ChallengeDto> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  }) async {
    final now = DateTime.now();
    final challenge = ChallengeDto(
      id: 'mock-challenge-${now.microsecondsSinceEpoch}',
      name: name,
      plannedDays: plannedDays,
      status: ChallengeStatus.active,
      startedAt: now,
      endedAt: null,
      createdAt: now,
      totalCount: discoveryIds.length,
      visitedCount: 0,
      isDue: false,
      items: [
        for (var index = 0; index < discoveryIds.length; index++)
          ChallengeItemDto(
            id: '${discoveryIds[index]}-item',
            discoveryId: discoveryIds[index],
            position: index,
            visitedAt: null,
            focusType: 'word',
            focusId: discoveryIds[index],
            title: discoveryIds[index],
          ),
      ],
    );
    _challenges.add(challenge);
    return challenge;
  }

  @override
  Future<ChallengeDto> fetchById(String id) async {
    return _challenges.firstWhere((challenge) => challenge.id == id);
  }

  @override
  Future<ChallengeDto> markVisited(String challengeId, String itemId) async {
    final challenge = await fetchById(challengeId);
    final items = challenge.items
        .map(
          (item) => item.id == itemId && item.visitedAt == null
              ? ChallengeItemDto(
                  id: item.id,
                  discoveryId: item.discoveryId,
                  position: item.position,
                  visitedAt: DateTime.now(),
                  focusType: item.focusType,
                  focusId: item.focusId,
                  title: item.title,
                  subtitle: item.subtitle,
                )
              : item,
        )
        .toList();
    final updated = _copy(challenge, items: items);
    _replace(updated);
    return updated;
  }

  @override
  Future<ChallengeDto> end(String id) async {
    final challenge = await fetchById(id);
    final updated = _copy(
      challenge,
      status: ChallengeStatus.ended,
      endedAt: DateTime.now(),
    );
    _replace(updated);
    return updated;
  }

  ChallengeDto _copy(
    ChallengeDto source, {
    ChallengeStatus? status,
    DateTime? endedAt,
    List<ChallengeItemDto>? items,
  }) {
    final nextItems = items ?? source.items;
    return ChallengeDto(
      id: source.id,
      name: source.name,
      plannedDays: source.plannedDays,
      status: status ?? source.status,
      startedAt: source.startedAt,
      endedAt: endedAt ?? source.endedAt,
      createdAt: source.createdAt,
      totalCount: nextItems.length,
      visitedCount: nextItems.where((item) => item.visitedAt != null).length,
      isDue: source.isDue,
      items: nextItems,
    );
  }

  void _replace(ChallengeDto challenge) {
    final index = _challenges.indexWhere((item) => item.id == challenge.id);
    if (index >= 0) {
      _challenges[index] = challenge;
    }
  }
}
