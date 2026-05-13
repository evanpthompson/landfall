import 'package:test/test.dart';

import 'package:landfall_server/src/theme/ssrf_guard.dart';

void main() {
  group('SsrfGuard.classifyUrl', () {
    // Pure (no DNS) checks — these must reject before any network call.
    group('synchronous string-based rejections', () {
      test('rejects non-HTTPS scheme', () {
        expect(
          SsrfGuard.classifyUrl('http://example.com/theme.yaml').accepted,
          isFalse,
        );
      });

      test('accepts a plain HTTPS URL with a public hostname', () {
        final c = SsrfGuard.classifyUrl('https://example.com/theme.yaml');
        expect(c.accepted, isTrue);
      });

      group('IPv4 literals', () {
        for (final host in const [
          '127.0.0.1',
          '127.5.6.7',
          '0.0.0.0',
          '169.254.169.254',
          '192.168.1.10',
          '10.0.0.1',
          '172.16.0.1',
          '172.31.255.255',
          '100.64.0.1', // CGNAT
        ]) {
          test('rejects literal $host', () {
            final c = SsrfGuard.classifyUrl('https://$host/theme.yaml');
            expect(c.accepted, isFalse, reason: 'host $host should be rejected');
          });
        }
      });

      group('IPv4 alternative encodings', () {
        // Hex, decimal-long, and short-form notations bypass naive string checks.
        for (final host in const [
          '0x7f000001', // hex 127.0.0.1
          '2130706433', // decimal 127.0.0.1
          '127.1', // short-form 127.0.0.1
          '0x7f.0x0.0x0.0x1', // dotted-hex 127.0.0.1
        ]) {
          test('rejects alt-encoded $host', () {
            final c = SsrfGuard.classifyUrl('https://$host/theme.yaml');
            expect(c.accepted, isFalse, reason: 'host $host should be rejected');
          });
        }
      });

      group('IPv6 literals (URL-bracketed)', () {
        for (final host in const [
          '[::1]', // loopback
          '[::ffff:127.0.0.1]', // IPv4-mapped loopback
          '[fc00::1]', // unique-local
          '[fd12:3456::1]', // unique-local
          '[fe80::1]', // link-local
        ]) {
          test('rejects literal $host', () {
            final c = SsrfGuard.classifyUrl('https://$host/theme.yaml');
            expect(c.accepted, isFalse, reason: 'host $host should be rejected');
          });
        }
      });

      test('rejects localhost variants', () {
        for (final host in const [
          'localhost',
          'LOCALHOST',
          'localhost.localdomain',
        ]) {
          expect(
            SsrfGuard.classifyUrl('https://$host/x').accepted,
            isFalse,
            reason: 'host $host should be rejected',
          );
        }
      });
    });
  });

  group('SsrfGuard.isPrivateAddress', () {
    // Used after DNS resolution to defeat DNS rebinding — a public hostname
    // that resolves to a private IP is still unsafe.
    for (final addr in const [
      '127.0.0.1',
      '10.5.6.7',
      '192.168.1.1',
      '172.16.0.1',
      '172.20.0.1',
      '172.31.255.254',
      '169.254.0.1',
      '100.64.0.1',
      '0.0.0.0',
      '::1',
      'fc00::1',
      'fd00::1',
      'fe80::1',
      '::ffff:127.0.0.1',
    ]) {
      test('flags $addr as private', () {
        expect(SsrfGuard.isPrivateAddress(addr), isTrue,
            reason: '$addr should be flagged as private');
      });
    }

    for (final addr in const [
      '8.8.8.8',
      '1.1.1.1',
      '172.32.0.1', // just outside RFC1918 172.16/12
      '172.15.255.255',
      '2606:4700:4700::1111', // Cloudflare DNS
    ]) {
      test('passes public address $addr', () {
        expect(SsrfGuard.isPrivateAddress(addr), isFalse,
            reason: '$addr should not be flagged as private');
      });
    }
  });
}
