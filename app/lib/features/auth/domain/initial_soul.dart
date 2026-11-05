class InitialSoul {
  const InitialSoul({required this.nativeLanguage, this.age, this.gender});

  final String nativeLanguage;
  final int? age;
  final String? gender;

  Map<String, Object?> toJson() {
    return {
      'native_language': nativeLanguage,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
    };
  }
}
