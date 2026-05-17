/// Single source of truth for the UUID stored in
/// [LinkedCredential.authUserId] and surfaced to clients via
/// [SettingsEndpoint.getMyAuthUserId].
///
/// Why this exists: two different callsites previously derived a UUID from
/// [Session.authenticated.userIdentifier] using two different format strings
/// (one v4-shaped, one all-zero). A credential created via the OAuth route
/// could not be matched against a query produced by the settings endpoint,
/// so re-linking silently created duplicate rows. The function below is the
/// canonical derivation; every callsite that needs an `authUserId` must call
/// this function.
///
/// Format: RFC 4122 v4 layout — `00000000-0000-4000-8000-<padded>`.
///
/// Why v4: the database holds rows created via this format from the alpha
/// OAuth flow, so the canonical format is the one that's already on disk.
/// The all-zero variant has never been written to disk in practice.
library;

/// Canonical UUID for an authenticated user.
///
/// [userIdentifier] is the value of `Session.authenticated.userIdentifier`.
/// Two shapes are supported because Serverpod's auth identifier evolved
/// over its release history:
///
/// * **Numeric** (legacy auth): up to 12 decimal digits. Padded with leading
///   zeros into the last group of the canonical UUID. Inputs longer than 12
///   digits would corrupt the UUID layout and are rejected.
/// * **UUID** (newer UUID-based auth): a valid RFC 4122 string. Returned
///   verbatim — the database already holds it in that exact form, and
///   reformatting would create lookup mismatches.
///
/// Throws [ArgumentError] for empty input or anything that isn't one of the
/// two accepted shapes. The route layer is expected to translate that into
/// a 4xx response; this function does not assume an HTTP context.
String authUserIdFromIdentifier(String userIdentifier) {
  if (userIdentifier.isEmpty) {
    throw ArgumentError.value(
      userIdentifier,
      'userIdentifier',
      'must not be empty',
    );
  }

  if (_uuidPattern.hasMatch(userIdentifier)) {
    return userIdentifier;
  }

  if (_numericPattern.hasMatch(userIdentifier)) {
    if (userIdentifier.length > 12) {
      throw ArgumentError.value(
        userIdentifier,
        'userIdentifier',
        'numeric identifier exceeds 12 digits; cannot be padded into UUID '
            'layout without truncation',
      );
    }
    final padded = userIdentifier.padLeft(12, '0');
    return '00000000-0000-4000-8000-$padded';
  }

  throw ArgumentError.value(
    userIdentifier,
    'userIdentifier',
    'must be either a numeric identifier (≤12 digits) or a valid UUID',
  );
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

final _numericPattern = RegExp(r'^[0-9]+$');
