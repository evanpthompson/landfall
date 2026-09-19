/// Thrown by a repository when the server refuses the client's credentials.
///
/// Distinct from a transport failure: the call reached the server and the
/// server rejected it, so retrying cannot help. The stored session has to be
/// discarded and the user has to sign in again. Callers translate this into a
/// return to the login screen rather than an on-screen error, because a display
/// showing "Authentication required" has no way for anyone to act on it.
class SessionExpiredException implements Exception {
  const SessionExpiredException([
    this.message = 'The display session is no longer valid.',
  ]);

  final String message;

  @override
  String toString() => 'SessionExpiredException: $message';
}
