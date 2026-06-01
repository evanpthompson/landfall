import 'dart:io';

/// Resolves the base URL a phone on the household LAN should use to reach this
/// server — for both the companion page (`/c/<id>`) and the device-auth
/// verification page (`/device`).
///
/// Resolution order:
///   1. `LANDFALL_DOMAIN` env var (set by `firstboot.sh` on Pi images) →
///      `https://$LANDFALL_DOMAIN`. This is the Caddy-fronted hostname that
///      mDNS resolves on the LAN; Caddy terminates TLS on :443 and proxies the
///      `/device` and `/c/**` paths to the web server. No port is appended.
///   2. The host's first non-loopback, non-link-local RFC1918 IPv4 address
///      with the default web-server port (`:8082`). Covers macOS / Fire TV
///      development where the Flutter app talks to Serverpod directly with no
///      Caddy in front.
///   3. Empty string — caller falls back to a request-derived origin or its
///      build-time define.
///
/// The phone must be on the same LAN as the host for branch 1 or 2 to work;
/// the URL is not designed to be internet-reachable. Only RFC1918 IPv4 is
/// accepted for branch 2 so a public IP can never be advertised.
///
/// [environment] and [listIpv4Addresses] are injectable for tests; production
/// callers omit them and get [Platform.environment] / a live interface scan.
Future<String> resolveLanBaseUrl({
  Map<String, String>? environment,
  Future<List<String>> Function()? listIpv4Addresses,
}) async {
  final env = environment ?? Platform.environment;
  final domain = env['LANDFALL_DOMAIN'];
  if (domain != null && domain.isNotEmpty) {
    return 'https://$domain';
  }
  final addresses = await (listIpv4Addresses ?? _listHostIpv4Addresses)();
  final lan = firstPrivateLanIpv4(addresses);
  if (lan != null) {
    return 'http://$lan:8082';
  }
  return '';
}

/// Returns the first RFC1918 IPv4 address in [addresses], or null if none
/// qualify. Pure — the testable core of [resolveLanBaseUrl]'s branch 2.
String? firstPrivateLanIpv4(Iterable<String> addresses) {
  for (final address in addresses) {
    if (isPrivateLanIpv4(address)) return address;
  }
  return null;
}

/// Whether [address] is an RFC1918 private IPv4 address
/// (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).
///
/// Loopback, link-local, public, and IPv6 are excluded — otherwise an
/// advertised URL could embed a public IP and be reachable across the internet.
bool isPrivateLanIpv4(String address) {
  final parts = address.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final a = parts[0]!, b = parts[1]!;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  return false;
}

Future<List<String>> _listHostIpv4Addresses() async {
  try {
    final ifaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    return [
      for (final iface in ifaces)
        for (final addr in iface.addresses) addr.address,
    ];
  } on SocketException {
    // No interfaces available — degrade to the empty-base fallback.
    return const [];
  }
}
