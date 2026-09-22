import 'package:test/test.dart';

import 'package:landfall_server/src/net/lan_base_url.dart';

void main() {
  group('isPrivateLanIpv4', () {
    test('accepts only RFC1918 IPv4 ranges', () {
      const accepted = [
        '10.0.0.1',
        '10.255.255.255',
        '172.16.0.1',
        '172.31.255.255',
        '192.168.0.1',
        '192.168.7.42',
      ];
      const rejected = [
        '127.0.0.1', // loopback
        '169.254.1.1', // link-local
        '8.8.8.8', // public
        '172.15.0.1', // just below RFC1918 172.16/12
        '172.32.0.1', // just above RFC1918 172.16/12
        '::1', // IPv6
        'not.an.ip', // garbage
      ];
      for (final a in accepted) {
        expect(isPrivateLanIpv4(a), isTrue, reason: '$a should qualify');
      }
      for (final a in rejected) {
        expect(isPrivateLanIpv4(a), isFalse, reason: '$a should not qualify');
      }
    });
  });

  group('firstPrivateLanIpv4', () {
    test('returns the first RFC1918 address, skipping non-qualifying ones', () {
      expect(
        firstPrivateLanIpv4(['127.0.0.1', '8.8.8.8', '192.168.1.5', '10.0.0.1']),
        '192.168.1.5',
      );
    });

    test('returns null when no address qualifies', () {
      expect(firstPrivateLanIpv4(['127.0.0.1', '8.8.8.8']), isNull);
    });
  });

  group('resolveLanBaseUrl', () {
    test('LANDFALL_DOMAIN takes precedence over any derived LAN IP', () async {
      final url = await resolveLanBaseUrl(
        environment: {'LANDFALL_DOMAIN': 'kitchen-pi.local'},
        listIpv4Addresses: () async => ['192.168.1.5'],
      );
      expect(url, 'https://kitchen-pi.local');
    });

    test('falls back to RFC1918 IP on :8082 when no domain is set', () async {
      final url = await resolveLanBaseUrl(
        environment: const {},
        listIpv4Addresses: () async => ['127.0.0.1', '192.168.7.42'],
      );
      expect(url, 'http://192.168.7.42:8082');
    });

    test('never advertises 127.0.0.1', () async {
      final url = await resolveLanBaseUrl(
        environment: const {},
        listIpv4Addresses: () async => ['127.0.0.1'],
      );
      expect(url, isNot(contains('127.0.0.1')));
      expect(url, isEmpty);
    });

    test('empty when neither a domain nor an RFC1918 address is available',
        () async {
      final url = await resolveLanBaseUrl(
        environment: const {},
        listIpv4Addresses: () async => const [],
      );
      expect(url, isEmpty);
    });
  });
}
