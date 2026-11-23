import '../../../discover/data/dto/discover_dto.dart';
import '../../domain/practice_word.dart';

class PracticeWordDto {
  const PracticeWordDto({
    required this.id,
    required this.label,
    required this.word,
    required this.audio,
    required this.context,
    required this.options,
    required this.practiceCount,
  });

  factory PracticeWordDto.fromJson(Map<String, dynamic> json) {
    final rawWord = json['content'];
    final rawAudio = json['audio'];
    return PracticeWordDto(
      id: json['id'] as String? ?? '',
      label: json['label_en'] as String? ?? '',
      word: rawWord is Map<String, dynamic>
          ? DiscoveredWordDto.fromJson(rawWord)
          : null,
      audio: rawAudio is Map<String, dynamic>
          ? WordAudioDto.fromJson(rawAudio)
          : null,
      context: json['context'] as String?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      practiceCount: (json['practice_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String label;
  final DiscoveredWordDto? word;
  final WordAudioDto? audio;
  final String? context;
  final List<String> options;
  final int practiceCount;

  PracticeWord toDomain() {
    return PracticeWord(
      id: id,
      label: label,
      word: word?.toDomain(),
      audio: audio?.toDomain(),
      context: context,
      options: options,
      practiceCount: practiceCount,
    );
  }
}

class PracticeCompleteDto {
  const PracticeCompleteDto({
    required this.wordId,
    required this.practiceCount,
  });

  factory PracticeCompleteDto.fromJson(Map<String, dynamic> json) {
    return PracticeCompleteDto(
      wordId: json['word_id'] as String? ?? '',
      practiceCount: (json['practice_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String wordId;
  final int practiceCount;
}

class PracticeReplyDto {
  const PracticeReplyDto({
    required this.reply,
    required this.recast,
    required this.nativeReply,
  });

  factory PracticeReplyDto.fromJson(Map<String, dynamic> json) {
    return PracticeReplyDto(
      reply: json['reply'] as String? ?? '',
      recast: json['recast'] as String?,
      nativeReply: json['native_reply'] as String?,
    );
  }

  final String reply;
  final String? recast;
  final String? nativeReply;

  PracticeReply toDomain() {
    return PracticeReply(reply: reply, recast: recast);
  }
}
