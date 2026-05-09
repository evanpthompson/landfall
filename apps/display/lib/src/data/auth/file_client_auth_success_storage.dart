import 'dart:convert';
import 'dart:io';

import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

/// File-based [ClientAuthSuccessStorage] for Linux kiosk deployments.
///
/// Stores the full [AuthSuccess] (including access token, expiry, and refresh
/// token) as JSON so [ClientAuthSessionManager] can auto-refresh the access
/// token before it expires, keeping the display authenticated indefinitely.
class FileClientAuthSuccessStorage implements ClientAuthSuccessStorage {
  FileClientAuthSuccessStorage({String? path})
      : _path = path ??
            '${Platform.environment['HOME'] ?? '/home/landfall'}/.landfall_auth.json';

  final String _path;
  AuthSuccess? _cache;

  @override
  Future<void> set(AuthSuccess? data) async {
    _cache = data;
    final file = File(_path);
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
      final file = File(_path);
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
