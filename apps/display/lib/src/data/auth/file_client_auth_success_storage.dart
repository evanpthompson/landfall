import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

/// File-based [ClientAuthSuccessStorage] for kiosk deployments.
///
/// Stores the full [AuthSuccess] (including access token, expiry, and refresh
/// token) as JSON so [ClientAuthSessionManager] can auto-refresh the access
/// token before it expires, keeping the display authenticated indefinitely.
///
/// Uses [getApplicationDocumentsDirectory] so the path is correct on all
/// platforms (Linux, macOS, Android/Fire TV) without hardcoding HOME.
class FileClientAuthSuccessStorage implements ClientAuthSuccessStorage {
  FileClientAuthSuccessStorage({String? overridePath})
      : _pathFuture = overridePath != null
            ? Future.value(overridePath)
            : _resolvePath();

  final Future<String> _pathFuture;
  AuthSuccess? _cache;

  static Future<String> _resolvePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'landfall_auth.json');
  }

  @override
  Future<void> set(AuthSuccess? data) async {
    final path = await _pathFuture;
    _cache = data;
    final file = File(path);
    if (data == null) {
      try {
        await file.delete();
      } catch (_) {}
    } else {
      await file.writeAsString(jsonEncode(data.toJson()));
    }
  }

  @override
  Future<AuthSuccess?> get() async {
    if (_cache != null) return _cache;
    try {
      final path = await _pathFuture;
      final file = File(path);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      _cache = AuthSuccess.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return _cache;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    _cache = null;
  }
}
