enum CompanionGender {
  female('female'),
  male('male'),
  preferNotToSay('prefer_not_to_say');

  const CompanionGender(this.wireValue);

  final String wireValue;

  static CompanionGender? fromWire(String? value) {
    for (final gender in values) {
      if (gender.wireValue == value) {
        return gender;
      }
    }
    return null;
  }
}

class CompanionProfile {
  const CompanionProfile({
    this.name,
    this.gender,
    this.hobby,
    required this.avatarKey,
    required this.voiceKey,
    required this.setupDismissed,
  });

  final String? name;
  final CompanionGender? gender;
  final String? hobby;
  final String avatarKey;
  final String voiceKey;
  final bool setupDismissed;

  bool get isNamed => name != null && name!.trim().isNotEmpty;

  bool get hasHobby => hobby != null && hobby!.trim().isNotEmpty;
}
