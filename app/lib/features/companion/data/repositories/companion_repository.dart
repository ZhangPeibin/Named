import '../../domain/companion_presence.dart';
import '../../domain/companion_profile.dart';
import '../api/companion_api.dart';

class CompanionRepository {
  const CompanionRepository(this._api);

  final CompanionApi _api;

  Future<CompanionProfile> fetch() async {
    return (await _api.fetchCompanion()).toDomain();
  }

  Future<CompanionProfile> updateProfile({
    required String name,
    CompanionGender? gender,
    String? hobby,
  }) async {
    final changes = <String, dynamic>{
      'name': name,
      'hobby': hobby ?? '',
      if (gender != null) 'gender': gender.wireValue,
    };
    return (await _api.updateCompanion(changes)).toDomain();
  }

  Future<CompanionProfile> dismissSetup() async {
    return (await _api.updateCompanion({'setup_dismissed': true})).toDomain();
  }

  Future<String> suggestName() {
    return _api.suggestName();
  }

  Future<CompanionProfile> assignRandomName() async {
    return (await _api.assignRandomName()).toDomain();
  }

  Future<CompanionPresence> fetchPresence({required int localHour}) async {
    return (await _api.fetchPresence(localHour: localHour)).toDomain();
  }
}
