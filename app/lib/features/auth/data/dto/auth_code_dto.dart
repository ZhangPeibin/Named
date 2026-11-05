class AuthCodeDto {
  const AuthCodeDto({required this.expiresIn, required this.resendAfter});

  final int expiresIn;
  final int resendAfter;

  factory AuthCodeDto.fromJson(Map<String, dynamic> json) {
    return AuthCodeDto(
      expiresIn: json['expires_in'] as int? ?? 600,
      resendAfter: json['resend_after'] as int? ?? 60,
    );
  }
}
