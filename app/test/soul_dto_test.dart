import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/soul/data/dto/soul_dto.dart';

void main() {
  test('parses the soul profile and items', () {
    final dto = SoulDto.fromJson({
      'profile': {'native_language': 'zh', 'age': 30, 'gender': 'female'},
      'items': [
        {
          'id': 'item-1',
          'kind': 'interest',
          'text': 'gardening',
          'source': 'onboarding',
        },
      ],
    });

    final soul = dto.toDomain();
    expect(soul.nativeLanguage, 'zh');
    expect(soul.age, 30);
    expect(soul.gender, 'female');
    expect(soul.items, hasLength(1));
    expect(soul.items.first.text, 'gardening');
    expect(soul.items.first.source, 'onboarding');
  });

  test('allows optional age, gender, and items', () {
    final soul = SoulDto.fromJson({
      'profile': {'native_language': 'en'},
      'items': <Object?>[],
    }).toDomain();

    expect(soul.nativeLanguage, 'en');
    expect(soul.age, isNull);
    expect(soul.gender, isNull);
    expect(soul.items, isEmpty);
  });

  test('rejects a missing native language', () {
    expect(
      () => SoulDto.fromJson({
        'profile': <String, Object?>{},
        'items': <Object?>[],
      }),
      throwsFormatException,
    );
  });
}
