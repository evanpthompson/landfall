// Scheme and host checks applied before launching URLs from card actions.
// Guards against javascript:, file://, and SSRF via private IP ranges.
// OWASP A06:2025.

const _allowedBrowserSchemes = {'https', 'http'};

// Webhooks are HTTPS-only — HTTP webhooks expose payload data on the wire.
const _allowedWebhookSchemes = {'https'};

/// Returns true if [url] is safe to open in the system browser.
///
/// Allows http and https. Blocks javascript:, file://, data:, and anything
/// else that could execute code or access the local filesystem.
bool isAllowedBrowserUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return _allowedBrowserSchemes.contains(uri.scheme);
}

/// Returns true if [url] is safe to use as a webhook target.
///
/// Requires HTTPS. Blocks loopback, link-local, and RFC-1918 private ranges
/// to prevent using the display device as an SSRF proxy against the local
/// network.
bool isAllowedWebhookUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (!_allowedWebhookSchemes.contains(uri.scheme)) return false;
  return !_isPrivateHost(uri.host.toLowerCase());
}

bool _isPrivateHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') return true;
  if (host == '169.254.169.254') return true;
  if (host.startsWith('192.168.')) return true;
  if (host.startsWith('10.')) return true;
  // RFC-1918: 172.16.0.0/12 covers 172.16.x.x – 172.31.x.x
  final parts = host.split('.');
  if (parts.length == 4 && parts[0] == '172') {
    final second = int.tryParse(parts[1]) ?? -1;
    if (second >= 16 && second <= 31) return true;
  }
  return false;
}
