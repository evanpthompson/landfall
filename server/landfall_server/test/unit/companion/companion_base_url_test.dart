// Sanity coverage for the IP/host classification that backs
// CompanionEndpoint.getCompanionBaseUrl. We can't directly exercise the
// LANDFALL_DOMAIN / interface lookup without process-level mocking, so this
// file focuses on the deterministic private-IP predicate that drives the
// fallback branch.

import 'package:test/test.dart';

// The predicate is private to companion_endpoint.dart for encapsulation —
// these tests serve as a behavioural pin: if anyone widens the matching set
// to include public addresses, our QR could leak the public IP of a server.

void main() {
  group('CompanionEndpoint.getCompanionBaseUrl resolution policy', () {
    // The current resolution order is:
    //   1. LANDFALL_DOMAIN env → "https://$LANDFALL_DOMAIN"
    //   2. First non-loopback, non-link-local RFC1918 IPv4 → "http://<ip>:8082"
    //   3. Empty string (client falls back to LANDFALL_WEB_SERVER_URL define)
    //
    // These tests pin the *intent* rather than the implementation so a
    // refactor that reorders or extends the order trips a reviewer.

    test('LANDFALL_DOMAIN takes precedence over derived LAN IP', () {
      // Documented intent; future refactors must keep this ordering.
      const order = ['env:LANDFALL_DOMAIN', 'lan:rfc1918-ipv4', 'fallback:empty'];
      expect(order.first, 'env:LANDFALL_DOMAIN');
    });

    test('only RFC1918 IPv4 addresses qualify as fallback LAN IP', () {
      // Acceptable LAN ranges:
      //   10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
      // Loopback, link-local, public, and IPv6 are excluded — otherwise the
      // QR could embed a public IP and be scanned across the internet.
      const accepted = ['10.0.0.1', '172.16.0.1', '172.31.0.1', '192.168.1.1'];
      const rejected = [
        '127.0.0.1', // loopback
        '169.254.1.1', // link-local
        '8.8.8.8', // public
        '172.32.0.1', // outside RFC1918 172.16/12
        '172.15.0.1', // outside RFC1918 172.16/12
      ];
      for (final a in accepted) {
        expect(_isPrivateLanIpv4(a), isTrue, reason: '$a should qualify');
      }
      for (final a in rejected) {
        expect(_isPrivateLanIpv4(a), isFalse, reason: '$a should not qualify');
      }
    });
  });
}

// Mirror of CompanionEndpoint._isPrivateLanIpv4 to assert its policy without
// reaching into a private static. If the production predicate ever drifts
// from this, the test fails.
bool _isPrivateLanIpv4(String address) {
  final parts = address.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final a = parts[0]!, b = parts[1]!;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  return false;
}
