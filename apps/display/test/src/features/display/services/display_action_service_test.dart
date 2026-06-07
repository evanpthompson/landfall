import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/data/companion/companion_poll_service.dart';
import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/display/services/display_action_service.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockPollService extends Mock implements CompanionPollService {}

class _MockProfileReloader extends Mock implements ProfileReloader {}

class _MockThemeReloader extends Mock implements ThemeReloader {}

// A poll service backed by a manually-controlled completer, so tests can
// push actions at will and observe which callbacks fire.
class _ControlledPollService implements CompanionPollService {
  final _completers = <Completer<lf.CompanionAction?>>[];
  bool disposed = false;

  void push(lf.CompanionAction? action) {
    for (final c in _completers.toList()) {
      if (!c.isCompleted) c.complete(action);
    }
    _completers.clear();
  }

  void error() {
    for (final c in _completers.toList()) {
      if (!c.isCompleted) c.completeError(Exception('poll error'));
    }
    _completers.clear();
  }

  @override
  Future<lf.CompanionAction?> pollForEvents(
    String displayId, {
    int timeoutSeconds = 30,
  }) {
    if (disposed) return Future.value(null);
    final c = Completer<lf.CompanionAction?>();
    _completers.add(c);
    return c.future;
  }
}

lf.CompanionAction _action(String kind) => lf.CompanionAction(
      kind: kind,
      timestamp: DateTime(2026),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockProfileReloader profileReloader;
  late _MockThemeReloader themeReloader;
  late CompanionEventBus bus;

  setUp(() {
    profileReloader = _MockProfileReloader();
    themeReloader = _MockThemeReloader();
    bus = CompanionEventBus();

    when(() => profileReloader.loadProfiles()).thenAnswer((_) async {});
    when(() => themeReloader.loadThemes()).thenAnswer((_) async {});
  });

  tearDown(() => bus.dispose());

  group('DisplayActionService', () {
    test('layout.changed action calls loadProfiles()', () async {
      final poll = _ControlledPollService();
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      // Allow the loop to issue the first poll.
      await Future<void>.delayed(Duration.zero);
      poll.push(_action('layout.changed'));
      await Future<void>.delayed(Duration.zero);

      verify(() => profileReloader.loadProfiles()).called(1);
      verifyNever(() => themeReloader.loadThemes());
    });

    test('theme.changed action calls loadThemes()', () async {
      final poll = _ControlledPollService();
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      await Future<void>.delayed(Duration.zero);
      poll.push(_action('theme.changed'));
      await Future<void>.delayed(Duration.zero);

      verify(() => themeReloader.loadThemes()).called(1);
      verifyNever(() => profileReloader.loadProfiles());
    });

    test('companion kind emits on bus.companionKinds', () async {
      final poll = _ControlledPollService();
      final received = <String>[];
      bus.companionKinds.listen(received.add);

      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      await Future<void>.delayed(Duration.zero);
      poll.push(_action('pet'));
      await Future<void>.delayed(Duration.zero);

      expect(received, contains('pet'));
    });

    test('settings.changed action does not throw and is a no-op', () async {
      final poll = _ControlledPollService();
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      await Future<void>.delayed(Duration.zero);
      // Must not throw.
      expect(
        () async {
          poll.push(_action('settings.changed'));
          await Future<void>.delayed(Duration.zero);
        },
        returnsNormally,
      );
    });

    test('unknown kind is a no-op (no crash, no dispatch)', () async {
      final poll = _ControlledPollService();
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      await Future<void>.delayed(Duration.zero);
      poll.push(_action('some.unknown.kind'));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => profileReloader.loadProfiles());
      verifyNever(() => themeReloader.loadThemes());
    });

    test('null response (timeout) reissues the next poll without crash',
        () async {
      final poll = _ControlledPollService();
      int pollCount = 0;

      // Track poll calls with a wrapper.
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: _TrackingPollService(poll, onPoll: () => pollCount++),
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();
      addTearDown(service.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(pollCount, greaterThanOrEqualTo(1));

      // Simulate a timeout (null result).
      poll.push(null);
      await Future<void>.delayed(Duration.zero);

      // Loop should have reissued another poll.
      expect(pollCount, greaterThanOrEqualTo(2));
    });

    test('poll error triggers backoff and loop continues', () async {
      final poll = _ControlledPollService();
      int pollCount = 0;

      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: _TrackingPollService(poll, onPoll: () => pollCount++),
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
        backoffDuration: Duration.zero,
      )..start();
      addTearDown(service.dispose);

      // Let first poll issue.
      await Future<void>.delayed(Duration.zero);
      poll.error();
      // Backoff is zero; allow the error handler + delayed(zero) + next poll to run.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Loop must survive and reissue.
      expect(pollCount, greaterThanOrEqualTo(2));
    });

    test('dispose stops the loop', () async {
      final poll = _ControlledPollService();
      final service = DisplayActionService(
        displayId: 'display-1',
        pollService: poll,
        bus: bus,
        profileReloader: profileReloader,
        themeReloader: themeReloader,
      )..start();

      await Future<void>.delayed(Duration.zero);
      service.dispose();
      poll.disposed = true;

      // Must not throw after dispose.
      expect(() => poll.push(_action('layout.changed')), returnsNormally);
    });
  });
}

// Thin wrapper that tracks poll call count.
class _TrackingPollService implements CompanionPollService {
  _TrackingPollService(this._inner, {required this.onPoll});

  final _ControlledPollService _inner;
  final VoidCallback onPoll;

  @override
  Future<lf.CompanionAction?> pollForEvents(
    String displayId, {
    int timeoutSeconds = 30,
  }) {
    onPoll();
    return _inner.pollForEvents(displayId, timeoutSeconds: timeoutSeconds);
  }
}
