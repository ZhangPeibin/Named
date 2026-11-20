class DailyWord {
  const DailyWord({
    required this.text,
    required this.startChar,
    required this.endChar,
    required this.beginMs,
    required this.endMs,
  });

  final String text;
  final int startChar;
  final int endChar;
  final int beginMs;
  final int endMs;
}

class DailyRead {
  const DailyRead({
    required this.date,
    required this.title,
    required this.passage,
    required this.targetWords,
    required this.question,
    required this.audioUrl,
    this.words = const [],
    this.completed = false,
    this.streak = 0,
    this.durationSeconds,
  });

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
}

class DailyTranslationLine {
  const DailyTranslationLine({
    required this.text,
    required this.startChar,
    required this.endChar,
    required this.translation,
  });

  final String text;
  final int startChar;
  final int endChar;
  final String translation;
}

class DailyTranslation {
  const DailyTranslation({required this.language, required this.lines});

  final String language;
  final List<DailyTranslationLine> lines;
}

class DailyCompletion {
  const DailyCompletion({
    required this.date,
    required this.streak,
    required this.wordCount,
    required this.targetWords,
    required this.durationSeconds,
  });

  final DateTime date;
  final int streak;
  final int wordCount;
  final List<String> targetWords;
  final int? durationSeconds;
}
