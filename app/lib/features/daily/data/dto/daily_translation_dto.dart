import '../../domain/daily_read.dart';

class DailyTranslationDto {
  const DailyTranslationDto({required this.language, required this.lines});

  factory DailyTranslationDto.fromJson(Map<String, dynamic> json) {
    return DailyTranslationDto(
      language: json['language'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (line) => DailyTranslationLine(
              text: line['text'] as String? ?? '',
              startChar: (line['start_char'] as num?)?.toInt() ?? 0,
              endChar: (line['end_char'] as num?)?.toInt() ?? 0,
              translation: line['translation'] as String? ?? '',
            ),
          )
          .toList(),
    );
  }

  final String language;
  final List<DailyTranslationLine> lines;

  DailyTranslation toDomain() {
    return DailyTranslation(language: language, lines: lines);
  }
}
