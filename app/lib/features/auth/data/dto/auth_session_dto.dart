class AuthSessionDto {
  const AuthSessionDto({required this.sessionToken, required this.isNew});

  final String sessionToken;
  final bool isNew;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final token = json['session_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Missing session_token');
    }
    return AuthSessionDto(
      sessionToken: token,
      isNew: json['is_new'] as bool? ?? false,
    );
  }
}
