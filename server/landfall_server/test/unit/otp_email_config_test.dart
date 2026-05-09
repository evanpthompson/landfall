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
  });
}
