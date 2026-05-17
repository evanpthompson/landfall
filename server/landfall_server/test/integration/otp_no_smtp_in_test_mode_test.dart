import 'package:test/test.dart';

import 'package:landfall_server/src/auth/otp_email_sender.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Regression guard: OtpEmailSender must never make an outbound SMTP
/// connection when the server is running in test mode. The 2026-05-17 OTP
/// integration test run hit real Gmail SMTP because `passwords.yaml` (shared
/// across run modes) had live SMTP credentials, and Gmail's bounce-back for
/// addresses like `user@example.com` reached the SMTP account owner's inbox.
///
/// The fix lives in `OtpEmailSender.sendCode` — an early return when
/// `session.server.runMode == ServerpodRunMode.test`. This test calls
/// sendCode with a bogus SMTP host that would fail the TCP connect within
/// the 15-second mailer timeout. If the skip ever regresses, this test will
/// hang or throw instead of completing in milliseconds.
void main() {
  withServerpod(
    'OtpEmailSender (test mode SMTP guard)',
    (sessionBuilder, endpoints) {
      test(
        'sendCode returns without attempting SMTP even with live config',
        () async {
          final session = sessionBuilder.build();
          const sender = OtpEmailSender();

          // Times out at 15 seconds inside mailer.send if the skip regresses.
          // We give this test 5 seconds — comfortably less, but more than
          // enough for a no-op log + return.
          final stopwatch = Stopwatch()..start();
          await sender.sendCode(
            session,
            email: 'should-never-be-mailed@example.com',
            code: '123456',
            lifetime: const Duration(minutes: 10),
          );
          stopwatch.stop();

          expect(
            stopwatch.elapsed.inSeconds,
            lessThan(5),
            reason:
                'sendCode took ${stopwatch.elapsed} — suspect it actually '
                'attempted an SMTP connection, which means the test-mode '
                'skip in OtpEmailSender.sendCode has regressed.',
          );

          await session.close();
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    },
  );
}
