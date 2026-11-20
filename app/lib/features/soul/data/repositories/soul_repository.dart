import '../../domain/soul.dart';
import '../api/soul_api.dart';

class SoulRepository {
  const SoulRepository(this._api);

  final SoulApi _api;

  Future<Soul> fetchSoul() async {
    return (await _api.fetchSoul()).toDomain();
  }

  Future<SoulItem> createItem({
    required String kind,
    required String text,
  }) async {
    return (await _api.createItem(kind: kind, text: text)).toDomain();
  }

  Future<SoulItem> updateItem({
    required String id,
    required String kind,
    required String text,
  }) async {
    return (await _api.updateItem(id: id, kind: kind, text: text)).toDomain();
  }

  Future<void> deleteItem(String id) {
    return _api.deleteItem(id);
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
