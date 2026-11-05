import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/storage/shared_preferences_key_value_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Required so the SharedPreferences platform channel mock is wired before any
  // call to SharedPreferences.getInstance().
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesKeyValueStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesKeyValueStorage(prefs);
  });

  test('writes and reads back typed values', () async {
    await storage.setString('user.name', 'Alice');
    await storage.setInt('user.age', 30);
    await storage.setBool('user.subscribed', true);

    expect(await storage.getString('user.name'), 'Alice');
    expect(await storage.getInt('user.age'), 30);
    expect(await storage.getBool('user.subscribed'), isTrue);
  });

  test('returns null for missing keys', () async {
    expect(await storage.getString('missing'), isNull);
    expect(await storage.getInt('missing'), isNull);
    expect(await storage.getBool('missing'), isNull);
  });

  test('containsKey and remove update existence', () async {
    await storage.setString('token', 'abc');

    expect(await storage.containsKey('token'), isTrue);

    await storage.remove('token');

    expect(await storage.containsKey('token'), isFalse);
    expect(await storage.getString('token'), isNull);
  });

  test('clear removes every key', () async {
    await storage.setString('a', '1');
    await storage.setInt('b', 2);

    await storage.clear();

    expect(await storage.containsKey('a'), isFalse);
    expect(await storage.containsKey('b'), isFalse);
  });
}
