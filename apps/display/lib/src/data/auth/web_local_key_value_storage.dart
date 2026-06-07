import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:web/web.dart' as web;

/// [KeyValueStorage] backed by `window.localStorage` for web deployments.
///
/// Used to persist the [AuthSuccess] JWT in the browser so that the web
/// settings UI remains signed in across page reloads.
class WebLocalKeyValueStorage implements KeyValueStorage {
  const WebLocalKeyValueStorage();

  @override
  Future<String?> get(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      web.window.localStorage.removeItem(key);
    } else {
      web.window.localStorage.setItem(key, value);
    }
  }
}
