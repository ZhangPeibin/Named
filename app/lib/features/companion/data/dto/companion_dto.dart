import '../../domain/companion_presence.dart';
import '../../domain/companion_profile.dart';

class CompanionProfileDto {
  const CompanionProfileDto({
    this.name,
    this.gender,
    this.hobby,
    required this.avatarKey,
    required this.voiceKey,
    required this.setupDismissed,
  });

  factory CompanionProfileDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final hobby = json['hobby'];
    return CompanionProfileDto(
      name: name is String && name.trim().isNotEmpty ? name : null,
      gender: CompanionGender.fromWire(json['gender'] as String?),
      hobby: hobby is String && hobby.trim().isNotEmpty ? hobby : null,
      avatarKey: json['avatar_key'] as String? ?? 'companion_chill',
      voiceKey: json['voice_key'] as String? ?? 'companion_default',
      setupDismissed: json['setup_dismissed'] as bool? ?? false,
    );
  }

  final String? name;
  final CompanionGender? gender;
  final String? hobby;
  final String avatarKey;
  final String voiceKey;
  final bool setupDismissed;

  CompanionProfile toDomain() {
    return CompanionProfile(
      name: name,
      gender: gender,
      hobby: hobby,
      avatarKey: avatarKey,
      voiceKey: voiceKey,
      setupDismissed: setupDismissed,
    );
  }
}

class CompanionNameSuggestionDto {
  const CompanionNameSuggestionDto({required this.name});

  factory CompanionNameSuggestionDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Missing companion name');
    }
    return CompanionNameSuggestionDto(name: name);
  }

  final String name;
}

class CompanionPresenceDto {
  const CompanionPresenceDto({
    required this.key,
    required this.variant,
    this.word,
  });

  factory CompanionPresenceDto.fromJson(Map<String, dynamic> json) {
    final params = json['params'] as Map<String, dynamic>? ?? const {};
    final word = params['word'];
    return CompanionPresenceDto(
      key: json['key'] as String? ?? 'fallback',
      variant: json['variant'] as int? ?? 0,
      word: word is String && word.trim().isNotEmpty ? word : null,
    );
  }

  final String key;
  final int variant;
  final String? word;

  CompanionPresence toDomain() {
    return CompanionPresence(key: key, variant: variant, word: word);
  }
}
