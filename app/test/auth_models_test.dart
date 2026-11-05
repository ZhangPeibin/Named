import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/auth/data/dto/auth_code_dto.dart';
import 'package:named/features/auth/data/dto/auth_session_dto.dart';
import 'package:named/features/auth/domain/initial_soul.dart';

void main() {
  test('parses auth code response', () {
    final dto = AuthCodeDto.fromJson({'expires_in': 600, 'resend_after': 60});
    expect(dto.expiresIn, 600);
    expect(dto.resendAfter, 60);
  });

  test('parses auth session response', () {
    final dto = AuthSessionDto.fromJson({
      'session_token': 'token',
      'is_new': true,
    });
    expect(dto.sessionToken, 'token');
    expect(dto.isNew, isTrue);
  });

  test('rejects an empty session token', () {
    expect(
      () => AuthSessionDto.fromJson({'session_token': '', 'is_new': false}),
      throwsFormatException,
    );
  });

  test('serializes only provided initial soul fields', () {
    const minimal = InitialSoul(nativeLanguage: 'zh');
    expect(minimal.toJson(), {'native_language': 'zh'});

    const full = InitialSoul(nativeLanguage: 'en', age: 30, gender: 'female');
    expect(full.toJson(), {
      'native_language': 'en',
      'age': 30,
      'gender': 'female',
    });
  });
}
