import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/companion_api.dart';
import '../data/repositories/companion_repository.dart';
import '../domain/companion_profile.dart';

final companionApiProvider = Provider<CompanionApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockCompanionApi();
  }
  return RemoteCompanionApi(ref.watch(dioProvider));
});

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  return CompanionRepository(ref.watch(companionApiProvider));
});

final companionProvider = FutureProvider.autoDispose<CompanionProfile>((ref) {
  return ref.watch(companionRepositoryProvider).fetch();
});

final companionControllerProvider = Provider<CompanionController>((ref) {
  return CompanionController(ref);
});

class CompanionController {
  CompanionController(this._ref);

  final Ref _ref;

  Future<CompanionProfile> saveProfile({
    required String name,
    CompanionGender? gender,
    String? hobby,
  }) async {
    final profile = await _ref
        .read(companionRepositoryProvider)
        .updateProfile(name: name, gender: gender, hobby: hobby);
    _ref.invalidate(companionProvider);
    return profile;
  }

  Future<void> dismissSetup() async {
    await _ref.read(companionRepositoryProvider).dismissSetup();
    _ref.invalidate(companionProvider);
  }

  Future<CompanionProfile> useRandomName() async {
    final profile = await _ref
        .read(companionRepositoryProvider)
        .assignRandomName();
    _ref.invalidate(companionProvider);
    return profile;
  }

  Future<String> suggestName() {
    return _ref.read(companionRepositoryProvider).suggestName();
  }
}
