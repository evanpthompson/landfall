import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/cards/widgets/url_safety.dart';

void main() {
  group('isAllowedBrowserUrl', () {
    group('allowed schemes', () {
      test('https:// is allowed', () {
        expect(isAllowedBrowserUrl('https://example.com'), isTrue);
      });

      test('http:// is allowed', () {
        expect(isAllowedBrowserUrl('http://example.com'), isTrue);
      });
    });

    group('blocked schemes', () {
      test('javascript: is blocked', () {
        expect(isAllowedBrowserUrl('javascript:alert(1)'), isFalse);
      });

      test('file:// is blocked', () {
        expect(isAllowedBrowserUrl('file:///etc/passwd'), isFalse);
      });

      test('data: is blocked', () {
        expect(isAllowedBrowserUrl('data:text/html,<h1>hi</h1>'), isFalse);
      });

      test('ftp:// is blocked', () {
        expect(isAllowedBrowserUrl('ftp://files.example.com'), isFalse);
      });
    });

    test('empty string is blocked', () {
      expect(isAllowedBrowserUrl(''), isFalse);
    });

    test('unparseable string is blocked', () {
      expect(isAllowedBrowserUrl('not a url at all %%%'), isFalse);
    });
  });

  group('isAllowedWebhookUrl', () {
    group('allowed', () {
      test('https:// public host is allowed', () {
        expect(isAllowedWebhookUrl('https://api.example.com/hook'), isTrue);
      });
    });

    group('blocked schemes', () {
      test('http:// is blocked for webhooks', () {
        expect(isAllowedWebhookUrl('http://api.example.com/hook'), isFalse);
      });

      test('javascript: is blocked', () {
        expect(isAllowedWebhookUrl('javascript:void(0)'), isFalse);
      });

      test('file:// is blocked', () {
        expect(isAllowedWebhookUrl('file:///etc/passwd'), isFalse);
      });
    });

    group('private IP blocking', () {
      test('localhost is blocked', () {
        expect(isAllowedWebhookUrl('https://localhost/hook'), isFalse);
      });

      test('127.0.0.1 is blocked', () {
        expect(isAllowedWebhookUrl('https://127.0.0.1/hook'), isFalse);
      });

      test('::1 (IPv6 loopback) is blocked', () {
        expect(isAllowedWebhookUrl('https://[::1]/hook'), isFalse);
      });

      test('169.254.169.254 (cloud metadata) is blocked', () {
        expect(
          isAllowedWebhookUrl('https://169.254.169.254/latest/meta-data'),
          isFalse,
        );
      });

      test('192.168.x.x is blocked', () {
        expect(isAllowedWebhookUrl('https://192.168.1.1/admin'), isFalse);
      });

      test('10.x.x.x is blocked', () {
        expect(isAllowedWebhookUrl('https://10.0.0.1/hook'), isFalse);
      });

      test('172.16.x.x is blocked', () {
        expect(isAllowedWebhookUrl('https://172.16.0.1/hook'), isFalse);
      });

      test('172.31.x.x is blocked', () {
        expect(isAllowedWebhookUrl('https://172.31.255.254/hook'), isFalse);
      });

      test('172.15.x.x is allowed (outside private range)', () {
        expect(isAllowedWebhookUrl('https://172.15.0.1/hook'), isTrue);
      });

      test('172.32.x.x is allowed (outside private range)', () {
        expect(isAllowedWebhookUrl('https://172.32.0.1/hook'), isTrue);
      });
    });

    test('empty string is blocked', () {
      expect(isAllowedWebhookUrl(''), isFalse);
    });
  });
}
