import 'package:serverpod_client/serverpod_client.dart';

/// Common interface for storing and retrieving the Landfall JWT.
///
/// Implementations: [SecureStorageAuthKeyProvider] (mobile/desktop keychain),
/// [FileAuthKeyProvider] (Linux kiosk — no keyring required).
abstract class AuthKeyProvider implements ClientAuthKeyProvider {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
}
