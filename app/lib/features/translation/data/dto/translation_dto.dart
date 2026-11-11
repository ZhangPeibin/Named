import '../../domain/translation.dart';

class TranslationDto {
  const TranslationDto({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translatedText,
  });

  factory TranslationDto.fromJson(Map<String, dynamic> json) {
    return TranslationDto(
      sourceLanguage: json['source_language'] as String? ?? 'en',
      targetLanguage: json['target_language'] as String? ?? 'zh',
      translatedText: json['translated_text'] as String? ?? '',
    );
  }

  final String sourceLanguage;
  final String targetLanguage;
  final String translatedText;

  TranslationResult toDomain() {
    return TranslationResult(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      translatedText: translatedText,
    );
  }
}
