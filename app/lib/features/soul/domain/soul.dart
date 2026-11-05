class SoulItem {
  const SoulItem({
    required this.id,
    required this.kind,
    required this.text,
    required this.source,
  });

  final String id;
  final String kind;
  final String text;
  final String source;
}

class Soul {
  const Soul({
    required this.nativeLanguage,
    this.age,
    this.gender,
    this.items = const [],
  });

  final String nativeLanguage;
  final int? age;
  final String? gender;
  final List<SoulItem> items;
}
