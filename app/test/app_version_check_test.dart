import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/app_update/data/app_version_repository.dart';
import 'package:named/features/app_update/data/dto/app_version_check_dto.dart';

void main() {
  test('mock repository returns optional and force update variants', () async {
    const repository = MockAppVersionRepository();

    final optional = await repository.checkVersion();
    expect(optional.updateAvailable, isTrue);
    expect(optional.forceUpdate, isFalse);

    final forced = await repository.checkVersion(forceUpdate: true);
    expect(forced.updateAvailable, isTrue);
    expect(forced.forceUpdate, isTrue);
  });

  test('parses version check dto from json', () {
    final dto = AppVersionCheckDto.fromJson({
      'platform': 'ios',
      'current_version': '1.0.0',
      'current_build': 1,
      'latest_version': '1.2.0',
      'latest_build': '3',
      'min_supported_version': '1.0.0',
      'min_supported_build': 1,
      'update_available': true,
      'force_update': false,
      'store_url': 'https://example.com/app',
      'release_notes': 'fixes',
    });

    final domain = dto.toDomain();
    expect(domain.latestVersion, '1.2.0');
    expect(domain.latestBuild, 3);
    expect(domain.updateAvailable, isTrue);
    expect(domain.forceUpdate, isFalse);
  });
}
