import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/storage/flutter_secure_storage_adapter.dart';

void main() {
  // The adapter delegates to FlutterSecureStorage, which talks to the platform
  // via a MethodChannel. Mock that channel with an in-memory map so we can
  // exercise the adapter without a real keystore.
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<String, String> store;
  late FlutterSecureStorageAdapter adapter;

  setUp(() {
    store = <String, String>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return store[key];
        case 'write':
          store[key!] = args['value'] as String;
          return null;
        case 'delete':
          store.remove(key);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(key);
        case 'readAll':
          return Map<String, String>.from(store);
      }
      return null;
    });
    adapter = FlutterSecureStorageAdapter();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('writes and reads secure values', () async {
    await adapter.write('token', 'secret-value');

    expect(await adapter.read('token'), 'secret-value');
  });

  test('contains and delete update existence', () async {
    await adapter.write('token', 'secret-value');

    expect(await adapter.contains('token'), isTrue);

    await adapter.delete('token');

    expect(await adapter.contains('token'), isFalse);
    expect(await adapter.read('token'), isNull);
  });

  test('deleteAll wipes all keys', () async {
    await adapter.write('a', '1');
    await adapter.write('b', '2');

    await adapter.deleteAll();

    expect(await adapter.contains('a'), isFalse);
    expect(await adapter.contains('b'), isFalse);
  });
}
