import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

/// In-memory fake for testing the [KeyValueClientAuthSuccessStorage] + a
/// [KeyValueStorage] pair without a browser. Proves the storage layer is
/// fully abstract — [WebLocalKeyValueStorage] is the production binding that
/// delegates to localStorage, but the logic is the same.
class _FakeKeyValueStorage implements KeyValueStorage {
  final _store = <String, String>{};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

AuthSuccess _auth({String token = 'test-token'}) => AuthSuccess(
      authStrategy: AuthStrategy.session.name,
      token: token,
      authUserId: UuidValue.fromString('550e8400-e29b-41d4-a716-446655440000'),
      scopeNames: const {'email'},
    );

void main() {
  group('KeyValueClientAuthSuccessStorage via fake KeyValueStorage', () {
    late _FakeKeyValueStorage fake;
    late KeyValueClientAuthSuccessStorage storage;

    setUp(() {
      fake = _FakeKeyValueStorage();
      storage = KeyValueClientAuthSuccessStorage(keyValueStorage: fake);
    });

    test('get returns null when nothing stored', () async {
      expect(await storage.get(), isNull);
    });

    test('set stores and get retrieves the AuthSuccess', () async {
      await storage.set(_auth(token: 'abc-123'));
      final result = await storage.get();
      expect(result, isNotNull);
      expect(result!.token, equals('abc-123'));
    });

    test('set(null) removes stored value', () async {
      await storage.set(_auth());
      await storage.set(null);
      expect(await storage.get(), isNull);
    });

    test('updating token overwrites the previous value', () async {
      await storage.set(_auth(token: 'first'));
      await storage.set(_auth(token: 'second'));
      final result = await storage.get();
      expect(result!.token, equals('second'));
    });

    test('uses the configured storage key', () async {
      const key = 'my_custom_key';
      final custom = KeyValueClientAuthSuccessStorage(
        keyValueStorage: fake,
        authSuccessStorageKey: key,
      );
      await custom.set(_auth(token: 'keyed'));
      expect(fake._store.containsKey(key), isTrue);
      expect(fake._store.containsKey('serverpod_auth_success_key'), isFalse);
    });
  });
}
