import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serverpod_client/serverpod_client.dart';

import 'auth_key_provider.dart';

/// Stores the Landfall JWT in the platform keychain / secure storage.
///
/// Implements [AuthKeyProvider] so it can be passed directly to
/// [Client.authKeyProvider], automatically attaching the bearer token to
/// every authenticated request.
class SecureStorageAuthKeyProvider implements AuthKeyProvider {
  static const _tokenKey = 'landfall_access_token';

  final FlutterSecureStorage _storage;

  const SecureStorageAuthKeyProvider(this._storage);

  @override
  Future<String?> get authHeaderValue async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    return wrapAsBearerAuthHeaderValue(token);
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<String?> readToken() => _storage.read(key: _tokenKey);
}
