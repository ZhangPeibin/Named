class TranslationResult {
  const TranslationResult({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translatedText,
  });

  final String sourceLanguage;
  final String targetLanguage;
  final String translatedText;
}
