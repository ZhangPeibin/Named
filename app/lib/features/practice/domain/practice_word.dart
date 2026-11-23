import '../../discover/domain/discover.dart';

class PracticeWord {
  const PracticeWord({
    required this.id,
    required this.label,
    required this.word,
    required this.audio,
    required this.context,
    required this.options,
    required this.practiceCount,
  });

  final String id;
  final String label;
  final DiscoveredWord? word;
  final WordAudio? audio;
  final String? context;
  final List<String> options;
  final int practiceCount;
}

class PracticeReply {
  const PracticeReply({required this.reply, required this.recast});

  final String reply;
  final String? recast;
}

class PracticeTurn {
  const PracticeTurn({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}
