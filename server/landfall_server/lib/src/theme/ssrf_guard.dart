import 'dart:io';

/// Outcome of an SSRF classification check.
class SsrfClassification {
  const SsrfClassification.accepted()
      : accepted = true,
        reason = null;
  const SsrfClassification.rejected(this.reason) : accepted = false;

  final bool accepted;
  final String? reason;
}

/// Defence-in-depth checks for outbound URL fetches.
///
/// Two layers are exposed:
///
///   1. [classifyUrl] — pure, synchronous, string-based rejection of URLs
///      whose host clearly maps to a local, loopback, link-local, or
///      otherwise restricted address. Covers IPv4 alt encodings (hex,
///      decimal, short-form), IPv6 literals, and localhost aliases.
///
///   2. [isPrivateAddress] — applied to resolved DNS A/AAAA records before
///      the fetch is made. Defeats DNS rebinding where a public-looking
///      hostname resolves to RFC1918 / loopback / link-local.
///
/// Residual risk: between resolve and connect, an attacker controlling DNS
/// may flip the answer. The HTTP client should be configured with a short
/// timeout and the response size capped to bound impact.
class SsrfGuard {
  SsrfGuard._();

  /// Synchronous string-based classification. Does not perform DNS.
  static SsrfClassification classifyUrl(String url) {
    if (!url.startsWith('https://')) {
      return const SsrfClassification.rejected('Only HTTPS URLs are accepted.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return const SsrfClassification.rejected('URL is malformed.');
    }
    final host = uri.host.toLowerCase();

    if (_isRestrictedHostname(host)) {
      return const SsrfClassification.rejected(
        'URL refers to a restricted host.',
      );
    }

    final canonical = _canonicalIpv4(host);
    if (canonical != null && _isPrivateIpv4(canonical)) {
      return const SsrfClassification.rejected(
        'URL refers to a restricted host.',
      );
    }

    if (_looksLikeIpv6(host)) {
      // Strip brackets if Uri.host preserved them; Dart usually does not.
      final raw = host.startsWith('[') && host.endsWith(']')
          ? host.substring(1, host.length - 1)
          : host;
      if (_isPrivateIpv6(raw)) {
        return const SsrfClassification.rejected(
          'URL refers to a restricted host.',
        );
      }
    }

    return const SsrfClassification.accepted();
  }

  /// True when [address] is loopback, link-local, RFC1918 private, CGNAT,
  /// unspecified, or an IPv6 unique-local / link-local / mapped-private
  /// equivalent. Accepts numeric IPv4 or IPv6 strings (not hostnames).
  static bool isPrivateAddress(String address) {
    final canonical = _canonicalIpv4(address);
    if (canonical != null) return _isPrivateIpv4(canonical);
    return _isPrivateIpv6(address);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static const _localhostAliases = {
    'localhost',
    'localhost.localdomain',
    'ip6-localhost',
    'ip6-loopback',
  };

  static bool _isRestrictedHostname(String host) {
    return _localhostAliases.contains(host);
  }

  /// Returns a canonical dotted IPv4 string if [host] decodes to one under
  /// any of: standard dotted-quad, hex per octet, decimal-long (32-bit),
  /// or short-form (a, a.b, a.b.c). Returns null otherwise.
  static String? _canonicalIpv4(String host) {
    if (host.isEmpty || host.contains(':')) return null;

    int? parsePart(String s) {
      if (s.isEmpty) return null;
      if (s.startsWith('0x') || s.startsWith('0X')) {
        return int.tryParse(s.substring(2), radix: 16);
      }
      if (s.length > 1 && s.startsWith('0')) {
        // Octal — treat as decimal (lenient) to keep the check conservative.
        return int.tryParse(s);
      }
      return int.tryParse(s);
    }

    final parts = host.split('.');
    if (parts.isEmpty || parts.length > 4) return null;

    final nums = parts.map(parsePart).toList();
    if (nums.any((n) => n == null)) return null;

    int value;
    switch (nums.length) {
      case 1:
        value = nums[0]!;
        break;
      case 2:
        // a.b → a is high octet, b is the 24-bit remainder.
        if (nums[0]! < 0 || nums[0]! > 0xff) return null;
        if (nums[1]! < 0 || nums[1]! > 0xffffff) return null;
        value = (nums[0]! << 24) | nums[1]!;
        break;
      case 3:
        if (nums[0]! < 0 || nums[0]! > 0xff) return null;
        if (nums[1]! < 0 || nums[1]! > 0xff) return null;
        if (nums[2]! < 0 || nums[2]! > 0xffff) return null;
        value = (nums[0]! << 24) | (nums[1]! << 16) | nums[2]!;
        break;
      case 4:
        for (final n in nums) {
          if (n! < 0 || n > 0xff) return null;
        }
        value = (nums[0]! << 24) |
            (nums[1]! << 16) |
            (nums[2]! << 8) |
            nums[3]!;
        break;
      default:
        return null;
    }
    if (value < 0 || value > 0xffffffff) return null;
    return '${(value >> 24) & 0xff}.${(value >> 16) & 0xff}.'
        '${(value >> 8) & 0xff}.${value & 0xff}';
  }

  static bool _isPrivateIpv4(String canonical) {
    final parts = canonical.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;
    final a = parts[0], b = parts[1];
    if (a == 0) return true; // 0.0.0.0/8 unspecified
    if (a == 10) return true; // RFC1918
    if (a == 127) return true; // loopback
    if (a == 169 && b == 254) return true; // link-local + metadata
    if (a == 172 && b >= 16 && b <= 31) return true; // RFC1918
    if (a == 192 && b == 168) return true; // RFC1918
    if (a == 100 && b >= 64 && b <= 127) return true; // CGNAT
    if (a >= 224) return true; // multicast + reserved
    return false;
  }

  static bool _looksLikeIpv6(String host) {
    // Uri.host returns IPv6 without brackets in some Dart versions and with
    // brackets in others — accept either.
    final h = host.startsWith('[') && host.endsWith(']')
        ? host.substring(1, host.length - 1)
        : host;
    if (!h.contains(':')) return false;
    try {
      InternetAddress(h, type: InternetAddressType.IPv6);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static bool _isPrivateIpv6(String address) {
    final InternetAddress addr;
    try {
      addr = InternetAddress(address, type: InternetAddressType.IPv6);
    } on ArgumentError {
      return false;
    }
    if (addr.isLoopback) return true;
    if (addr.isLinkLocal) return true;
    if (addr.isMulticast) return true;
    final bytes = addr.rawAddress;
    if (bytes.length != 16) return false;
    // Unique local fc00::/7 → first byte 0xfc or 0xfd.
    if ((bytes[0] & 0xfe) == 0xfc) return true;
    // ::ffff:0:0/96 IPv4-mapped — check the embedded IPv4.
    final isV4Mapped = bytes.sublist(0, 10).every((b) => b == 0) &&
        bytes[10] == 0xff &&
        bytes[11] == 0xff;
    if (isV4Mapped) {
      final v4 = '${bytes[12]}.${bytes[13]}.${bytes[14]}.${bytes[15]}';
      return _isPrivateIpv4(v4);
    }
    // Unspecified ::
    if (bytes.every((b) => b == 0)) return true;
    return false;
  }
}
