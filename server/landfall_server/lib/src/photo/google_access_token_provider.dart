/// Source of OAuth 2.0 access tokens for the Google APIs.
///
/// Abstracted so the Drive photo services can take a fake in tests without
/// minting a real signed JWT.
///
/// Production implementations:
/// * [GoogleServiceAccountAuth] — service account self-signed JWT exchange
/// * (OAuth user-credential path manages tokens inline in
///   [GoogleDrivePhotoService] for now; refactoring it onto this interface
///   is a future cleanup.)
abstract class GoogleAccessTokenProvider {
  Future<String> getAccessToken();
}
