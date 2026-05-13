import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/auth/otp_email_sender.dart';

void main() {
  group('OtpEmailConfig', () {
    test('production without SMTP does not enable OTP code logging', () {
      final config = OtpEmailConfig.fromPasswords(
        const {},
        runMode: ServerpodRunMode.production,
      );

      expect(config.isConfigured, isFalse);
      expect(config.logCodes, isFalse);
    });

    test('test mode without SMTP allows OTP code logging', () {
      final config = OtpEmailConfig.fromPasswords(
        const {},
        runMode: ServerpodRunMode.test,
      );

      expect(config.isConfigured, isFalse);
      expect(config.logCodes, isTrue);
    });

    test('SMTP config is detected from passwords', () {
      final config = OtpEmailConfig.fromPasswords(
        const {
          'smtpHost': 'smtp.example.com',
          'smtpPort': '465',
          'smtpUsername': 'user',
          'smtpPassword': 'secret',
          'smtpFromEmail': 'noreply@example.com',
          'smtpFromName': 'Landfall Test',
          'smtpSsl': 'true',
          'smtpAllowInsecure': 'false',
        },
        runMode: ServerpodRunMode.production,
      );

      expect(config.isConfigured, isTrue);
      expect(config.host, 'smtp.example.com');
      expect(config.port, 465);
      expect(config.username, 'user');
      expect(config.password, 'secret');
      expect(config.fromEmail, 'noreply@example.com');
      expect(config.fromName, 'Landfall Test');
      expect(config.ssl, isTrue);
      expect(config.allowInsecure, isFalse);
      expect(config.logCodes, isFalse);
    });

    test('otpLogCodes password key forces logging even in production', () {
      final config = OtpEmailConfig.fromPasswords(
        const {'otpLogCodes': 'true'},
        runMode: ServerpodRunMode.production,
      );

      expect(config.logCodes, isTrue);
    });

    test('isConfigured requires both host and fromEmail', () {
      final hostOnly = OtpEmailConfig.fromPasswords(
        const {'smtpHost': 'smtp.example.com'},
        runMode: ServerpodRunMode.production,
      );
      expect(hostOnly.isConfigured, isFalse);

      final emailOnly = OtpEmailConfig.fromPasswords(
        const {'smtpFromEmail': 'noreply@example.com'},
        runMode: ServerpodRunMode.production,
      );
      expect(emailOnly.isConfigured, isFalse);
    });

    test('port defaults to 587 when not set', () {
      final config = OtpEmailConfig.fromPasswords(
        const {},
        runMode: ServerpodRunMode.production,
      );
      expect(config.port, equals(587));
    });

    test('port defaults to 587 for unparseable value', () {
      final config = OtpEmailConfig.fromPasswords(
        const {'smtpPort': 'not-a-number'},
        runMode: ServerpodRunMode.production,
      );
      expect(config.port, equals(587));
    });

    test('fromName defaults to Landfall when not set', () {
      final config = OtpEmailConfig.fromPasswords(
        const {},
        runMode: ServerpodRunMode.production,
      );
      expect(config.fromName, equals('Landfall'));
    });

    test('parseBool accepts 1 and yes in addition to true', () {
      final withOne = OtpEmailConfig.fromPasswords(
        const {
          'smtpHost': 'h',
          'smtpFromEmail': 'e@e.com',
          'smtpSsl': '1',
          'smtpAllowInsecure': 'yes',
        },
        runMode: ServerpodRunMode.production,
      );
      expect(withOne.ssl, isTrue);
      expect(withOne.allowInsecure, isTrue);
    });

    test('parseBool rejects false, no, and empty string', () {
      final config = OtpEmailConfig.fromPasswords(
        const {
          'smtpSsl': 'false',
          'smtpAllowInsecure': 'no',
          'otpLogCodes': '',
        },
        runMode: ServerpodRunMode.production,
      );
      expect(config.ssl, isFalse);
      expect(config.allowInsecure, isFalse);
      expect(config.logCodes, isFalse);
    });
  });
}
