import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/app/poll_timeouts.dart';

void main() {
  group('long-poll timeout invariant', () {
    test('the client waits longer than the server is asked to hold', () {
      // Serverpod wraps each request in Future.timeout, which abandons the
      // request without closing its socket. A client timeout shorter than the
      // hold therefore leaks one descriptor per poll — which is how a Pi ends
      // up pinned at its 1024-descriptor limit with a frozen dashboard.
      expect(
        kClientConnectionTimeout,
        greaterThan(kCompanionPollTimeout),
        reason: 'every long poll would time out client-side and leak a socket',
      );
    });

    test('and by a margin, not by a second', () {
      // The gap has to absorb the round trip and scheduling delay on a loaded
      // Pi. A one-second margin would leak whenever the device is busy —
      // exactly when it can least afford it.
      expect(
        kClientConnectionTimeout - kCompanionPollTimeout,
        greaterThanOrEqualTo(kPollTimeoutMargin),
      );
    });

    test('the poll is long enough to be worth holding open', () {
      // A short hold turns a long poll into a busy loop: reconnects cost a
      // socket handshake each time, on a device with 1024 of them.
      expect(kCompanionPollTimeout, greaterThanOrEqualTo(const Duration(seconds: 15)));
    });
  });
}
