import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/discover_dto.dart';

abstract class DiscoverApi {
  Future<DiscoverDto> createText({required String text, String? context});

  Future<DiscoverDto> fetch(String discoveryId);

  Future<DiscoverDto> focus({
    required String discoveryId,
    String? candidateId,
    String? labelEn,
    bool wholeScene = false,
  });
}

class RemoteDiscoverApi implements DiscoverApi {
  const RemoteDiscoverApi(this._dio);

  final Dio _dio;

  @override
  Future<DiscoverDto> createText({
    required String text,
    String? context,
  }) async {
    final form = FormData.fromMap({
      'text': text,
      if (context != null && context.trim().isNotEmpty) 'context': context,
    });
    return _guard(
      () => _dio.post<Map<String, dynamic>>('/api/v1/discoveries', data: form),
    );
  }

  @override
  Future<DiscoverDto> fetch(String discoveryId) async {
    return _guard(
      () => _dio.get<Map<String, dynamic>>('/api/v1/discoveries/$discoveryId'),
    );
  }

  @override
  Future<DiscoverDto> focus({
    required String discoveryId,
    String? candidateId,
    String? labelEn,
    bool wholeScene = false,
  }) async {
    final body = <String, dynamic>{};
    if (candidateId != null) {
      body['candidate_id'] = candidateId;
    }
    if (labelEn != null) {
      body['label_en'] = labelEn;
    }
    if (wholeScene) {
      body['whole_scene'] = true;
    }
    return _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/discoveries/$discoveryId/focus',
        data: body,
      ),
    );
  }

  Future<DiscoverDto> _guard(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: 'Discovery response was empty',
        );
      }
      return DiscoverDto.fromJson(data);
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

class MockDiscoverApi implements DiscoverApi {
  MockDiscoverApi({this.needsConfirmation = false});

  final bool needsConfirmation;
  final Map<String, DiscoverDto> _store = {};

  @override
  Future<DiscoverDto> createText({
    required String text,
    String? context,
  }) async {
    final dto = needsConfirmation
        ? _needsConfirmation(text, context)
        : _ready(text, context);
    _store[dto.id] = dto;
    return dto;
  }

  @override
  Future<DiscoverDto> fetch(String discoveryId) async {
    return _store[discoveryId] ?? _ready('notice', null);
  }

  @override
  Future<DiscoverDto> focus({
    required String discoveryId,
    String? candidateId,
    String? labelEn,
    bool wholeScene = false,
  }) async {
    final current = _store[discoveryId];
    final ready = _ready(
      labelEn ?? current?.inputText ?? 'notice',
      current?.context,
    );
    _store[discoveryId] = ready;
    return ready;
  }

  DiscoverDto _needsConfirmation(String text, String? context) {
    return DiscoverDto(
      id: 'mock-discovery',
      inputText: text,
      context: context,
      inputLanguage: 'en',
      status: 'needs_confirmation',
      focusKind: null,
      wordId: null,
      candidates: const [
        DiscoveryCandidateDto(
          id: 'candidate-1',
          labelEn: 'notice',
          labelZh: '注意到',
          confidence: 0.92,
          reason: 'Most likely the verb you mean.',
          selected: false,
        ),
        DiscoveryCandidateDto(
          id: 'candidate-2',
          labelEn: 'notice',
          labelZh: '通知',
          confidence: 0.61,
          reason: 'A noun with the same spelling.',
          selected: false,
        ),
      ],
      word: null,
      needsConfirmation: true,
      warnings: const [],
    );
  }

  DiscoverDto _ready(String text, String? context) {
    final fallback = text.trim().isEmpty
        ? 'notice'
        : text.trim().split(RegExp(r'\s+')).take(2).join(' ');
    final word = _wordFor(text, fallback);
    return DiscoverDto(
      id: 'mock-discovery',
      inputText: text,
      context: context,
      inputLanguage: 'en',
      status: 'ready',
      focusKind: 'word',
      wordId: 'mock-word',
      candidates: const [],
      word: word,
      needsConfirmation: false,
      warnings: const [],
    );
  }

  DiscoveredWordDto _wordFor(String input, String fallback) {
    final normalized = input.toLowerCase();
    if (normalized.contains('树') || normalized.contains('tree')) {
      return const DiscoveredWordDto(
        spelling: 'tree',
        ipa: {'us': '/triː/', 'uk': '/triː/'},
        pos: ['noun'],
        senses: [
          WordSenseDto(
            definitionEn: 'a tall plant with a trunk and branches',
            definitionZh: '有树干和树枝的高大植物',
            exampleEn: 'The tree is old.',
            exampleZh: '这棵树很老了。',
          ),
        ],
        grammar: 'countable noun · plural: trees',
        related: ['leaf', 'branch', 'trunk'],
        chunks: [
          WordChunkDto(
            phrase: 'a tall tree',
            meaningZh: '一棵高大的树',
            exampleEn: 'There is a tall tree by the lake.',
          ),
          WordChunkDto(
            phrase: 'under a tree',
            meaningZh: '在树下',
            exampleEn: 'We sat under a tree.',
          ),
          WordChunkDto(
            phrase: 'plant a tree',
            meaningZh: '种一棵树',
            exampleEn: 'They planted a tree in the garden.',
          ),
        ],
        varietyNotes: [],
        sceneExtensions: [
          SceneExtensionDto(
            labelEn: 'leaf',
            labelZh: '树叶',
            relationship: 'part of a tree',
          ),
          SceneExtensionDto(
            labelEn: 'branch',
            labelZh: '树枝',
            relationship: 'part of a tree',
          ),
          SceneExtensionDto(
            labelEn: 'trunk',
            labelZh: '树干',
            relationship: 'part of a tree',
          ),
          SceneExtensionDto(
            labelEn: 'forest',
            labelZh: '森林',
            relationship: 'a place with many trees',
          ),
        ],
      );
    }
    if (normalized.contains('雨') || normalized.contains('rain')) {
      return const DiscoveredWordDto(
        spelling: 'rain',
        ipa: {'us': '/reɪn/', 'uk': '/reɪn/'},
        pos: ['noun', 'verb'],
        senses: [
          WordSenseDto(
            definitionEn: 'water falling from the sky',
            definitionZh: '从天空落下的水；下雨',
            exampleEn: 'It started to rain.',
            exampleZh: '开始下雨了。',
          ),
        ],
        grammar: 'uncountable noun · verb: rain / rained',
        related: ['cloud', 'storm', 'wet'],
        chunks: [
          WordChunkDto(
            phrase: 'heavy rain',
            meaningZh: '大雨',
            exampleEn: 'We drove home in heavy rain.',
          ),
          WordChunkDto(
            phrase: 'in the rain',
            meaningZh: '在雨中',
            exampleEn: 'They walked in the rain.',
          ),
          WordChunkDto(
            phrase: 'rain or shine',
            meaningZh: '风雨无阻',
            exampleEn: 'The event happens rain or shine.',
          ),
        ],
        varietyNotes: [],
        sceneExtensions: [
          SceneExtensionDto(
            labelEn: 'umbrella',
            labelZh: '雨伞',
            relationship: 'used in the rain',
          ),
          SceneExtensionDto(
            labelEn: 'cloud',
            labelZh: '云',
            relationship: 'where rain comes from',
          ),
          SceneExtensionDto(
            labelEn: 'wet street',
            labelZh: '湿漉漉的街道',
            relationship: 'what rain leaves behind',
          ),
        ],
      );
    }
    if (normalized.contains('花') || normalized.contains('flower')) {
      return const DiscoveredWordDto(
        spelling: 'flower',
        ipa: {'us': '/ˈflaʊ.ɚ/', 'uk': '/ˈflaʊ.ər/'},
        pos: ['noun'],
        senses: [
          WordSenseDto(
            definitionEn: 'the colorful part of a plant',
            definitionZh: '植物开花的部分',
            exampleEn: 'I saw a small flower by the road.',
            exampleZh: '我注意到路边有一朵小花。',
          ),
        ],
        grammar: 'countable noun · plural: flowers',
        related: ['petal', 'bloom', 'plant'],
        chunks: [
          WordChunkDto(
            phrase: 'a flower shop',
            meaningZh: '花店',
            exampleEn: 'She stopped at a flower shop.',
          ),
          WordChunkDto(
            phrase: 'in bloom',
            meaningZh: '正在开花',
            exampleEn: 'The garden is in bloom.',
          ),
        ],
        varietyNotes: [],
        sceneExtensions: [
          SceneExtensionDto(
            labelEn: 'petal',
            labelZh: '花瓣',
            relationship: 'part of a flower',
          ),
          SceneExtensionDto(
            labelEn: 'bouquet',
            labelZh: '花束',
            relationship: 'a group of flowers',
          ),
        ],
      );
    }
    return DiscoveredWordDto(
      spelling: fallback,
      ipa: const {},
      pos: const ['word'],
      senses: [
        WordSenseDto(
          definitionEn: 'a word you noticed',
          definitionZh: '你注意到的一个词',
          exampleEn: fallback,
          exampleZh: '',
        ),
      ],
      grammar: '',
      related: const [],
      chunks: const [],
      varietyNotes: const [],
      sceneExtensions: const [],
    );
  }
}
