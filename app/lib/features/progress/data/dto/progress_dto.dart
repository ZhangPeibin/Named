import '../../domain/progress.dart';

class ProgressDto {
  const ProgressDto({
    required this.words,
    required this.conversations,
    required this.readings,
    required this.practices,
  });

  factory ProgressDto.fromJson(Map<String, dynamic> json) {
    return ProgressDto(
      words: (json['words'] as num?)?.toInt() ?? 0,
      conversations: (json['conversations'] as num?)?.toInt() ?? 0,
      readings: (json['readings'] as num?)?.toInt() ?? 0,
      practices: (json['practices'] as num?)?.toInt() ?? 0,
    );
  }

  final int words;
  final int conversations;
  final int readings;
  final int practices;

  Progress toDomain() {
    return Progress(
      words: words,
      conversations: conversations,
      readings: readings,
      practices: practices,
    );
  }
}
