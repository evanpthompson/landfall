import 'package:display/src/app/app_config.dart';
import 'package:display/src/app/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Telemetry is dev-build-only. In production builds (every release path)
/// it must compile to a no-op that emits zero network traffic.
///
/// These tests run with the default `--dart-define` state — i.e. no
/// `LANDFALL_TELEMETRY_ENDPOINT` set — so they verify the disabled path.
/// The enabled path is exercised manually + via the server-side route's
/// integration tests.
void main() {
  group('Telemetry (build defaults)', () {
    test('is disabled by default — endpoint constant is empty', () {
      expect(kLandfallTelemetryEndpoint, isEmpty);
      expect(kLandfallTelemetryApiKey, isEmpty);
      expect(Telemetry.isEnabled, isFalse);
    });

    test('Telemetry.event() is a synchronous no-op when disabled', () {
      // The call must not throw, must not hit the network, and must return
      // immediately. Marker: nothing to assert beyond "this didn't throw".
      Telemetry.event('app_launched');
      Telemetry.event('any_event', props: {'k': 'v', 'n': 42});
    });
  });
}
