import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/data/auth/file_auth_key_provider.dart';

void main() {
  late Directory tempDir;
  late String tempPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('landfall_key_test_');
    tempPath = '${tempDir.path}/landfall_token';
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('FileAuthKeyProvider', () {
    test('readToken returns null when no file exists', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      expect(await provider.readToken(), isNull);
    });

    test('authHeaderValue returns null when no token is saved', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      expect(await provider.authHeaderValue, isNull);
    });

    test('saveToken then readToken round-trips the value', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await provider.saveToken('my-jwt-token');
      expect(await provider.readToken(), equals('my-jwt-token'));
    });

    test('authHeaderValue wraps token as Bearer scheme', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await provider.saveToken('my-jwt-token');
      expect(await provider.authHeaderValue, equals('Bearer my-jwt-token'));
    });

    test('deleteToken removes the file', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await provider.saveToken('some-token');
      expect(File(tempPath).existsSync(), isTrue);
      await provider.deleteToken();
      expect(File(tempPath).existsSync(), isFalse);
    });

    test('readToken returns null after deleteToken', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await provider.saveToken('some-token');
      await provider.deleteToken();
      expect(await provider.readToken(), isNull);
    });

    test('readToken returns null for empty file', () async {
      await File(tempPath).writeAsString('');
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      expect(await provider.readToken(), isNull);
    });

    test('readToken returns null for whitespace-only file', () async {
      await File(tempPath).writeAsString('   \n  ');
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      expect(await provider.readToken(), isNull);
    });

    test('readToken trims whitespace from stored token', () async {
      await File(tempPath).writeAsString('  trimmed-token\n');
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      expect(await provider.readToken(), equals('trimmed-token'));
    });

    test('overridePath is used when provided', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await provider.saveToken('check-path');
      expect(File(tempPath).existsSync(), isTrue);
      expect(await File(tempPath).readAsString(), equals('check-path'));
    });

    test('deleteToken does not throw when file does not exist', () async {
      final provider = FileAuthKeyProvider(overridePath: tempPath);
      await expectLater(provider.deleteToken(), completes);
    });
  });
}
