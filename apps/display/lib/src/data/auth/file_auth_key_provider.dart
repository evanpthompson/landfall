import 'dart:io';

import 'package:serverpod_client/serverpod_client.dart';

import 'auth_key_provider.dart';

/// File-based JWT storage for Linux kiosk deployments.
///
/// On a single-user Pi there is no meaningful threat from other local users,
/// so storing the JWT in a plain file is acceptable and avoids the D-Bus
/// Secret Service dependency that flutter_secure_storage requires on Linux.
class FileAuthKeyProvider implements AuthKeyProvider {
  FileAuthKeyProvider({String? path})
      : _path = path ??
            '${Platform.environment['HOME'] ?? '/home/landfall'}/.landfall_token';

  final String _path;

  @override
  Future<String?> get authHeaderValue async {
    final token = await readToken();
    if (token == null) return null;
    return wrapAsBearerAuthHeaderValue(token);
  }

  @override
  Future<String?> readToken() async {
    try {
      final file = File(_path);
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveToken(String token) =>
      File(_path).writeAsString(token);

  @override
  Future<void> deleteToken() async {
    try {
      await File(_path).delete();
    } catch (_) {}
  }
}
