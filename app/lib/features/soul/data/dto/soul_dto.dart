import '../../domain/soul.dart';

class SoulItemDto {
  const SoulItemDto({
    required this.id,
    required this.kind,
    required this.text,
    required this.source,
  });

  factory SoulItemDto.fromJson(Map<String, dynamic> json) {
    return SoulItemDto(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'item',
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
    );
  }

  final String id;
  final String kind;
  final String text;
  final String source;

  SoulItem toDomain() {
    return SoulItem(id: id, kind: kind, text: text, source: source);
  }
}

class SoulDto {
  const SoulDto({
    required this.nativeLanguage,
    this.age,
    this.gender,
    required this.items,
  });

  factory SoulDto.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final nativeLanguage = profile['native_language'];
    if (nativeLanguage is! String || nativeLanguage.trim().isEmpty) {
      throw const FormatException('Missing native_language');
    }

    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SoulItemDto.fromJson)
        .toList();

    return SoulDto(
      nativeLanguage: nativeLanguage,
      age: profile['age'] as int?,
      gender: profile['gender'] as String?,
      items: items,
    );
  }

  final String nativeLanguage;
  final int? age;
  final String? gender;
  final List<SoulItemDto> items;

  Soul toDomain() {
    return Soul(
      nativeLanguage: nativeLanguage,
      age: age,
      gender: gender,
      items: items.map((item) => item.toDomain()).toList(),
    );
  }
}
