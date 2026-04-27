/// Thrown when the Landfall server returns a non-success response.
class LandfallClientException implements Exception {
  const LandfallClientException(this.message, {this.statusCode});

  final String message;

  /// The HTTP status code returned by the server, if available.
  final int? statusCode;

  @override
  String toString() => statusCode != null
      ? 'LandfallClientException($statusCode): $message'
      : 'LandfallClientException: $message';
}
