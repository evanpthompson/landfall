import 'package:test/test.dart';

// Import the generated test helper file, it contains everything you need.
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Greeting endpoint', (sessionBuilder, endpoints) {
    test('returns greeting including the provided name', () async {
      final authed = sessionBuilder.copyWith(
        authentication:
            AuthenticationOverride.authenticationInfo('user-1', {}),
      );
      final greeting = await endpoints.greeting.hello(authed, 'Bob');
      expect(greeting.message, 'Hello Bob');
    });
  });

  // SEC-02: GreetingEndpoint auth guard.
  withServerpod('Given Greeting endpoint auth guards', (sessionBuilder, endpoints) {
    test('hello rejects unauthenticated caller', () async {
      expect(
        () => endpoints.greeting.hello(sessionBuilder, 'World'),
        throwsA(isA<Exception>()),
      );
    });

    test('authenticated caller receives greeting (regression)', () async {
      final authed = sessionBuilder.copyWith(
        authentication:
            AuthenticationOverride.authenticationInfo('user-1', {}),
      );
      final greeting = await endpoints.greeting.hello(authed, 'World');
      expect(greeting.message, 'Hello World');
    });
  });
}
