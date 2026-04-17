import 'package:test/test.dart';

// Integration tests for CardEndpoint.
// Full tests require a live Serverpod test session with a connected database.
// See: https://docs.serverpod.dev/concepts/testing
//
// Phase 0 scaffold — tests will be fleshed out in Phase 2 alongside auth.
void main() {
  group('CardEndpoint', () {
    test('placeholder — integration tests added in Phase 2', () {
      // Phase 2 will add:
      // - pushCard creates a card and returns it
      // - pushCard with existing externalId updates in-place
      // - getCards excludes dismissed cards
      // - getCards excludes expired cards
      // - dismissCard sets dismissedAt and returns true
      // - dismissCard returns false for unknown externalId
      expect(true, isTrue);
    });
  });
}
