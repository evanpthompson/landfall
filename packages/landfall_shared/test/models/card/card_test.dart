import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  final baseTime = DateTime(2026, 4, 14, 12, 0, 0);

  Card makeCard({
    String id = 'card-1',
    String source = 'agent.claude',
    String title = 'Test Card',
    CardPriority priority = CardPriority.normal,
    bool persistent = false,
    DateTime? expiresAt,
    DateTime? dismissedAt,
    DateTime? createdAt,
  }) {
    return Card(
      id: id,
      source: source,
      title: title,
      layout: CardLayout.medium,
      priority: priority,
      persistent: persistent,
      expiresAt: expiresAt,
      dismissedAt: dismissedAt,
      createdAt: createdAt ?? baseTime,
    );
  }

  group('Card.isActive', () {
    test('dismissed card is not active', () {
      final card = makeCard(dismissedAt: baseTime);
      expect(card.isActive(baseTime.add(const Duration(minutes: 1))), isFalse);
    });

    test('persistent card is always active', () {
      final card = makeCard(persistent: true);
      expect(card.isActive(baseTime.add(const Duration(days: 365))), isTrue);
    });

    test('card with explicit expiresAt is active before expiry', () {
      final card = makeCard(
        expiresAt: baseTime.add(const Duration(hours: 1)),
      );
      expect(card.isActive(baseTime.add(const Duration(minutes: 30))), isTrue);
    });

    test('card with explicit expiresAt is inactive after expiry', () {
      final card = makeCard(
        expiresAt: baseTime.add(const Duration(hours: 1)),
      );
      expect(card.isActive(baseTime.add(const Duration(hours: 2))), isFalse);
    });

    test('normal priority card is active within 24 hours', () {
      final card = makeCard(priority: CardPriority.normal);
      expect(card.isActive(baseTime.add(const Duration(hours: 23))), isTrue);
    });

    test('normal priority card is inactive after 24 hours', () {
      final card = makeCard(priority: CardPriority.normal);
      expect(card.isActive(baseTime.add(const Duration(hours: 25))), isFalse);
    });

    test('ephemeral priority card is inactive after 2 hours', () {
      final card = makeCard(priority: CardPriority.ephemeral);
      expect(card.isActive(baseTime.add(const Duration(hours: 3))), isFalse);
    });

    test('persistent priority card never expires via TTL', () {
      final card = makeCard(priority: CardPriority.persistent);
      expect(card.isActive(baseTime.add(const Duration(days: 365))), isTrue);
    });
  });

  group('Card serialization', () {
    test('toJson / fromJson roundtrip preserves all fields', () {
      final card = makeCard(
        expiresAt: baseTime.add(const Duration(hours: 6)),
        dismissedAt: null,
      );
      final roundtripped = Card.fromJson(card.toJson());
      expect(roundtripped, equals(card));
    });

    test('toJson omits optional null fields', () {
      final card = makeCard();
      final json = card.toJson();
      expect(json.containsKey('body'), isFalse);
      expect(json.containsKey('expiresAt'), isFalse);
      expect(json.containsKey('dismissedAt'), isFalse);
      expect(json.containsKey('actions'), isFalse);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final minimal = {
        'id': 'card-1',
        'source': 'system.clock',
        'title': 'Clock',
        'layout': 'small',
        'priority': 'normal',
        'persistent': false,
        'createdAt': baseTime.toIso8601String(),
      };
      expect(() => Card.fromJson(minimal), returnsNormally);
    });
  });

  group('Card.copyWith', () {
    test('copyWith updates only specified fields', () {
      final original = makeCard(title: 'Original');
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, original.id);
      expect(updated.source, original.source);
    });
  });

  group('Card equality', () {
    test('cards with same id and fields are equal', () {
      expect(makeCard(), equals(makeCard()));
    });

    test('cards with different ids are not equal', () {
      expect(makeCard(id: 'a'), isNot(equals(makeCard(id: 'b'))));
    });
  });
}
