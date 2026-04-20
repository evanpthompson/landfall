import 'package:serverpod_auth_idp_server/providers/passkey.dart';

/// Exposes the Passkey authentication endpoints.
///
/// The passkey IDP handles WebAuthn challenge creation, passkey registration,
/// and passkey-based login. See [PasskeyIdpBaseEndpoint] for the full API.
class PasskeyIdpEndpoint extends PasskeyIdpBaseEndpoint {}
