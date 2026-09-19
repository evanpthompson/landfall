import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// The message every authenticated endpoint throws when the session is missing,
/// expired, or otherwise rejected — see `_requireAuth` on the server.
const authRequiredMessage = 'Authentication required.';

/// Runs [call], translating the server's authentication refusal into a
/// domain-level [SessionExpiredException].
///
/// Without this the refusal arrives as a generic [LandfallException] and gets
/// rendered as an error string on the wall display, where nobody can act on it.
/// As a typed domain error it can be routed back to the login screen instead.
/// Every other failure — transport errors, other domain exceptions — passes
/// through untouched.
Future<T> guardSession<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on LandfallException catch (e) {
    if (e.message == authRequiredMessage) {
      throw const SessionExpiredException();
    }
    rethrow;
  }
}
