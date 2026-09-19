import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/auth/session_guard.dart';

void main() {
  group('guardSession', () {
    test('returns the value when the call succeeds', () async {
      expect(await guardSession(() async => 42), 42);
    });

    test('translates the server auth refusal into SessionExpiredException',
        () async {
      expect(
        () => guardSession<void>(
          () async => throw LandfallException(
            message: 'Authentication required.',
          ),
        ),
        throwsA(isA<SessionExpiredException>()),
      );
    });

    test('leaves other LandfallExceptions untouched', () async {
      expect(
        () => guardSession<void>(
          () async => throw LandfallException(message: 'Rate limited.'),
        ),
        throwsA(
          isA<LandfallException>().having(
            (e) => e.message,
            'message',
            'Rate limited.',
          ),
        ),
      );
    });

    test('leaves transport failures untouched', () async {
      expect(
        () => guardSession<void>(() async => throw StateError('socket closed')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
