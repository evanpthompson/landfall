import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class OtpEmailSender {
  const OtpEmailSender();

  Future<void> sendCode(
    Session session, {
    required String email,
    required String code,
    required Duration lifetime,
  }) async {
    final config = OtpEmailConfig.fromSession(session);

    // Never make outbound SMTP connections in test runs — even when
    // passwords.yaml has live SMTP credentials. OTP integration tests use
    // addresses like `user@example.com`, and a real send through Gmail
    // produces bounce notifications back to the SMTP account owner. The
    // tests don't assert on email side effects, so logging is sufficient.
    final runMode = session.server.runMode;
    if (runMode == ServerpodRunMode.test) {
      session.log(
        '[OTP] (test mode) skipping SMTP send for $email '
        '(code suppressed; ${lifetime.inMinutes} min lifetime).',
      );
      return;
    }

    if (!config.isConfigured) {
      if (config.logCodes) {
        session.log(
          '[OTP] Code for $email: $code (expires in ${lifetime.inMinutes} min)',
        );
        return;
      }

      session.log('[OTP] SMTP delivery is not configured.');
      throw LandfallException(
        message: 'Email delivery is not configured.',
      );
    }

    final smtpServer = SmtpServer(
      config.host,
      port: config.port,
      ssl: config.ssl,
      allowInsecure: config.allowInsecure,
      username: config.username.isEmpty ? null : config.username,
      password: config.password.isEmpty ? null : config.password,
    );

    final message = mailer.Message()
      ..from = mailer.Address(config.fromEmail, config.fromName)
      ..recipients.add(email)
      ..subject = 'Your Landfall sign-in code'
      ..text = '''
Your Landfall sign-in code is:

$code

This code expires in ${lifetime.inMinutes} minutes. If you did not request it, you can ignore this email.
''';

    try {
      await mailer.send(
        message,
        smtpServer,
        timeout: const Duration(seconds: 15),
      );
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('[OTP] SMTP delivery failed for $email: $error\n$stackTrace');
      session.log(
        '[OTP] SMTP delivery failed for $email: $error',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      throw LandfallException(
        message: 'Could not send sign-in code.',
      );
    }
  }
}

class OtpEmailConfig {
  const OtpEmailConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.fromEmail,
    required this.fromName,
    required this.ssl,
    required this.allowInsecure,
    required this.logCodes,
  });

  factory OtpEmailConfig.fromSession(Session session) {
    return OtpEmailConfig.fromPasswords(
      session.passwords,
      runMode: session.server.runMode,
    );
  }

  factory OtpEmailConfig.fromPasswords(
    Map<String, String> passwords, {
    String runMode = ServerpodRunMode.production,
  }) {
    return OtpEmailConfig(
      host: passwords['smtpHost']?.trim() ?? '',
      port: int.tryParse(passwords['smtpPort'] ?? '') ?? 587,
      username: passwords['smtpUsername']?.trim() ?? '',
      password: passwords['smtpPassword'] ?? '',
      fromEmail: passwords['smtpFromEmail']?.trim() ?? '',
      fromName: passwords['smtpFromName']?.trim() ?? 'Landfall',
      ssl: _parseBool(passwords['smtpSsl']),
      allowInsecure: _parseBool(passwords['smtpAllowInsecure']),
      logCodes: _parseBool(passwords['otpLogCodes']) ||
          runMode != ServerpodRunMode.production,
    );
  }

  final String host;
  final int port;
  final String username;
  final String password;
  final String fromEmail;
  final String fromName;
  final bool ssl;
  final bool allowInsecure;
  final bool logCodes;

  bool get isConfigured => host.isNotEmpty && fromEmail.isNotEmpty;

  static bool _parseBool(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
