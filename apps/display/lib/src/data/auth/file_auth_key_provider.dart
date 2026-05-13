import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_client/serverpod_client.dart';

import 'auth_key_provider.dart';

/// File-based JWT storage for kiosk deployments.
///
/// On a single-user ambient display there is no meaningful threat from other
/// local users, so storing the JWT in a plain file is acceptable and avoids
/// the D-Bus Secret Service dependency that flutter_secure_storage requires
/// on Linux.
///
/// Uses [getApplicationDocumentsDirectory] so the path is correct on all
/// platforms (Linux, macOS, Android/Fire TV) without hardcoding HOME.
class FileAuthKeyProvider implements AuthKeyProvider {
  FileAuthKeyProvider({String? overridePath})
      : _pathFuture = overridePath != null
            ? Future.value(overridePath)
            : _resolvePath();

  final Future<String> _pathFuture;

  static Future<String> _resolvePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'landfall_token');
  }

  @override
  Future<String?> get authHeaderValue async {
    final token = await readToken();
    if (token == null) return null;
    return wrapAsBearerAuthHeaderValue(token);
  }

  @override
  Future<String?> readToken() async {
    try {
      final path = await _pathFuture;
      final file = File(path);
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    final path = await _pathFuture;
    await File(path).writeAsString(token);
  }

  @override
  Future<void> deleteToken() async {
    try {
      final path = await _pathFuture;
      await File(path).delete();
    } catch (_) {}
  }
}
