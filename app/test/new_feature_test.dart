import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/new_feature.dart' as new_feature;

void main() {
  test('full-slice generator scaffolds all layers with correct shape', () {
    _withTempProject((root) {
      new_feature.main(['profile']);

      final base = '${root.path}/lib/features/profile';
      final domain = File('$base/domain/profile.dart').readAsStringSync();
      final dto = File('$base/data/dto/profile_dto.dart').readAsStringSync();
      final api = File('$base/data/api/profile_api.dart').readAsStringSync();
      final repository = File(
        '$base/data/repositories/profile_repository.dart',
      ).readAsStringSync();
      final providers = File(
        '$base/providers/profile_providers.dart',
      ).readAsStringSync();
      final page = File(
        '$base/presentation/profile_page.dart',
      ).readAsStringSync();

      // Names are derived correctly from snake_case.
      expect(domain, contains('class Profile {'));
      expect(dto, contains('class ProfileDto {'));
      expect(dto, contains('Profile toDomain()'));
      expect(api, contains('class RemoteProfileApi implements ProfileApi'));
      expect(repository, contains('class ProfileRepository'));
      expect(providers, contains('final profileProvider'));
      expect(page, contains('class ProfilePage extends ConsumerWidget'));

      // Error boundary lives in the data layer.
      expect(api, contains('ApiException.fromDioException(error)'));

      // Architecture boundaries: domain is framework-free, presentation does
      // not touch infrastructure directly.
      expect(domain, isNot(contains('package:flutter')));
      expect(domain, isNot(contains('package:dio')));
      expect(page, isNot(contains('package:dio')));
      expect(page, isNot(contains('package:shared_preferences')));
    });
  });

  test('--ui-only generates only a presentation page', () {
    _withTempProject((root) {
      new_feature.main(['dashboard', '--ui-only']);

      final base = '${root.path}/lib/features/dashboard';
      expect(
        File('$base/presentation/dashboard_page.dart').existsSync(),
        isTrue,
      );
      expect(Directory('$base/data').existsSync(), isFalse);
      expect(Directory('$base/domain').existsSync(), isFalse);
      expect(Directory('$base/providers').existsSync(), isFalse);

      final page = File(
        '$base/presentation/dashboard_page.dart',
      ).readAsStringSync();
      expect(page, contains('class DashboardPage extends StatelessWidget'));
    });
  });

  test('multi-word names map to PascalCase / camelCase', () {
    _withTempProject((root) {
      new_feature.main(['user_profile']);

      final base = '${root.path}/lib/features/user_profile';
      expect(
        File('$base/domain/user_profile.dart').readAsStringSync(),
        contains('class UserProfile {'),
      );
      expect(
        File('$base/providers/user_profile_providers.dart').readAsStringSync(),
        contains('final userProfileProvider'),
      );
    });
  });
}

void _withTempProject(void Function(Directory root) body) {
  final root = Directory.systemTemp.createTempSync('flutter-template-feature-');
  addTearDown(() => root.deleteSync(recursive: true));
  File('${root.path}/pubspec.yaml').writeAsStringSync('name: fixture_app\n');
  Directory('${root.path}/lib/features').createSync(recursive: true);

  final originalDirectory = Directory.current;
  try {
    Directory.current = root;
    body(root);
  } finally {
    Directory.current = originalDirectory;
  }
}
