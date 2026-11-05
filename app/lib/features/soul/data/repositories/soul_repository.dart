import '../../domain/soul.dart';
import '../api/soul_api.dart';

class SoulRepository {
  const SoulRepository(this._api);

  final SoulApi _api;

  Future<Soul> fetchSoul() async {
    return (await _api.fetchSoul()).toDomain();
  }

  Future<Soul> updateSoul({
    required String nativeLanguage,
    int? age,
    String? gender,
  }) async {
    return (await _api.updateSoul(
      nativeLanguage: nativeLanguage,
      age: age,
      gender: gender,
    )).toDomain();
  }
}
