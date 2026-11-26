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
