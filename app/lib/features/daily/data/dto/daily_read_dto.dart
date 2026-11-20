import '../../domain/daily_read.dart';

class DailyReadDto {
  const DailyReadDto({
    required this.date,
    required this.title,
    required this.passage,
    required this.targetWords,
    required this.question,
    required this.audioUrl,
    required this.words,
    this.completed = false,
    this.streak = 0,
    this.durationSeconds,
  });

  factory DailyReadDto.fromJson(Map<String, dynamic> json) {
    final audio = json['audio'] as Map<String, dynamic>?;
    return DailyReadDto(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      title: json['title'] as String? ?? '',
      passage: json['passage'] as String? ?? '',
      targetWords: (json['target_words'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      question: json['question'] as String?,
      audioUrl: audio?['status'] == 'ready' ? (audio?['url'] as String?) : null,
      words: (json['words'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (word) => DailyWord(
              text: word['text'] as String? ?? '',
              startChar: (word['start_char'] as num?)?.toInt() ?? 0,
              endChar: (word['end_char'] as num?)?.toInt() ?? 0,
              beginMs: (word['begin_ms'] as num?)?.toInt() ?? 0,
              endMs: (word['end_ms'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
      completed: json['completed'] as bool? ?? false,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }

  final DateTime date;
  final String title;
  final String passage;
  final List<String> targetWords;
  final String? question;
  final String? audioUrl;
  final List<DailyWord> words;
  final bool completed;
  final int streak;
  final int? durationSeconds;

  DailyRead toDomain() {
    return DailyRead(
      date: date,
      title: title,
      passage: passage,
      targetWords: targetWords,
      question: question,
      audioUrl: audioUrl,
      words: words,
      completed: completed,
      streak: streak,
      durationSeconds: durationSeconds,
    );
  }
}

class DailyCompletionDto {
  const DailyCompletionDto({
    required this.date,
    required this.streak,
    required this.wordCount,
    required this.targetWords,
    required this.durationSeconds,
  });

  factory DailyCompletionDto.fromJson(Map<String, dynamic> json) {
    return DailyCompletionDto(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
      targetWords: (json['target_words'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }

  final DateTime date;
  final int streak;
  final int wordCount;
  final List<String> targetWords;
  final int? durationSeconds;

  DailyCompletion toDomain() {
    return DailyCompletion(
      date: date,
      streak: streak,
      wordCount: wordCount,
      targetWords: targetWords,
      durationSeconds: durationSeconds,
    );
  }
}
