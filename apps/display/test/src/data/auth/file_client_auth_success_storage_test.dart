import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:uuid/uuid.dart';

import 'package:display/src/data/auth/file_client_auth_success_storage.dart';

AuthSuccess _makeAuthSuccess({String token = 'test-token'}) => AuthSuccess(
      authStrategy: AuthStrategy.session.name,
      token: token,
      authUserId: UuidValue.fromString('550e8400-e29b-41d4-a716-446655440000'),
      scopeNames: const {'email'},
    );

void main() {
  late Directory tempDir;
  late String tempPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('landfall_auth_test_');
    tempPath = '${tempDir.path}/landfall_auth.json';
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('FileClientAuthSuccessStorage', () {
    test('get returns null when no file exists', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      expect(await storage.get(), isNull);
    });

    test('set then get round-trips AuthSuccess', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      final auth = _makeAuthSuccess();
      await storage.set(auth);
      final result = await storage.get();
      expect(result, isNotNull);
      expect(result!.token, equals(auth.token));
      expect(result.authUserId, equals(auth.authUserId));
    });

    test('set(null) deletes the persisted file', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      await storage.set(_makeAuthSuccess());
      expect(File(tempPath).existsSync(), isTrue);
      await storage.set(null);
      expect(File(tempPath).existsSync(), isFalse);
    });

    test('get returns null after set(null)', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      await storage.set(_makeAuthSuccess());
      await storage.set(null);
      expect(await storage.get(), isNull);
    });

    test('get returns null for empty file', () async {
      await File(tempPath).writeAsString('');
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      expect(await storage.get(), isNull);
    });

    test('get returns cached value without re-reading file', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      final auth = _makeAuthSuccess(token: 'cached-token');
      await storage.set(auth);
      // Corrupt file after first read — cache should still return original value
      final firstRead = await storage.get();
      await File(tempPath).writeAsString('garbage');
      final secondRead = await storage.get();
      expect(secondRead!.token, equals(firstRead!.token));
    });

    test('two instances with same path share file but not in-memory cache', () async {
      final s1 = FileClientAuthSuccessStorage(overridePath: tempPath);
      final s2 = FileClientAuthSuccessStorage(overridePath: tempPath);
      await s1.set(_makeAuthSuccess(token: 'shared-token'));
      final result = await s2.get();
      expect(result!.token, equals('shared-token'));
    });

    test('overridePath is used when provided', () async {
      final storage = FileClientAuthSuccessStorage(overridePath: tempPath);
      await storage.set(_makeAuthSuccess());
      expect(File(tempPath).existsSync(), isTrue);
    });
  });
}
