import 'package:landfall_agent_sdk/landfall_agent_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('CardDraftBuilder', () {
    test('build() with title produces CardDraft', () {
      final draft = CardDraft.build().title('Hello').source('agent.test')();
      expect(draft.title, equals('Hello'));
      expect(draft.source, equals('agent.test'));
    });

    test('throws StateError when title is missing', () {
      expect(
        () => CardDraft.build()(),
        throwsA(isA<StateError>()),
      );
    });

    test('defaults source to agent.sdk', () {
      final draft = CardDraft.build().title('T')();
      expect(draft.source, equals('agent.sdk'));
    });

    test('defaults layout to medium and priority to normal', () {
      final draft = CardDraft.build().title('T')();
      expect(draft.layout, equals(CardLayout.medium));
      expect(draft.priority, equals(CardPriority.normal));
    });

    test('expires() sets expiresAt relative to now', () {
      final before = DateTime.now().toUtc();
      final draft = CardDraft.build()
          .title('T')
          .expires(const Duration(hours: 4))();
      final after = DateTime.now().toUtc();

      expect(draft.expiresAt, isNotNull);
      expect(
        draft.expiresAt!.isAfter(before.add(const Duration(hours: 3, minutes: 59))),
        isTrue,
      );
      expect(
        draft.expiresAt!.isBefore(after.add(const Duration(hours: 4, minutes: 1))),
        isTrue,
      );
    });

    test('expiresAt() stores UTC timestamp', () {
      final ts = DateTime(2026, 6, 1, 12, 0, 0);
      final draft = CardDraft.build().title('T').expiresAt(ts)();
      expect(draft.expiresAt, equals(ts.toUtc()));
    });

    test('persistent() sets isPersistent flag', () {
      final draft = CardDraft.build().title('T').persistent()();
      expect(draft.isPersistent, isTrue);
    });

    test('cardId() sets the stable slot identifier', () {
      final draft = CardDraft.build().title('T').cardId('agent.myapp.slot')();
      expect(draft.cardId, equals('agent.myapp.slot'));
    });

    test('all fields round-trip through builder', () {
      final draft = CardDraft.build()
          .title('Full card')
          .source('agent.full')
          .body('Body text')
          .layout(CardLayout.large)
          .priority(CardPriority.ephemeral)
          .cardId('full.slot')();

      expect(draft.title, 'Full card');
      expect(draft.source, 'agent.full');
      expect(draft.body, 'Body text');
      expect(draft.layout, CardLayout.large);
      expect(draft.priority, CardPriority.ephemeral);
      expect(draft.cardId, 'full.slot');
    });
  });

  group('CardDraft.toRequestJson', () {
    test('includes __className__ for Serverpod deserialization', () {
      final json = CardDraft.build().title('T').source('agent.t')().toRequestJson();
      expect(json['__className__'], equals('CardPushRequest'));
    });

    test('maps layout and priority to string names', () {
      final json = CardDraft.build()
          .title('T')
          .source('agent.t')
          .layout(CardLayout.large)
          .priority(CardPriority.ephemeral)()
          .toRequestJson();
      expect(json['layout'], equals('large'));
      expect(json['priority'], equals('ephemeral'));
    });

    test('omits optional fields when not set', () {
      final json = CardDraft.build().title('T').source('agent.t')().toRequestJson();
      expect(json.containsKey('body'), isFalse);
      expect(json.containsKey('expiresAt'), isFalse);
      expect(json.containsKey('persistent'), isFalse);
      expect(json.containsKey('externalId'), isFalse);
    });

    test('includes externalId when cardId is set', () {
      final json =
          CardDraft.build().title('T').source('agent.t').cardId('slot-1')().toRequestJson();
      expect(json['externalId'], equals('slot-1'));
    });

    test('includes persistent: true when persistent() called', () {
      final json =
          CardDraft.build().title('T').source('agent.t').persistent()().toRequestJson();
      expect(json['persistent'], isTrue);
    });

    test('formats expiresAt as ISO 8601 UTC string', () {
      final ts = DateTime.utc(2026, 6, 1, 18, 0, 0);
      final json =
          CardDraft.build().title('T').source('agent.t').expiresAt(ts)().toRequestJson();
      expect(json['expiresAt'], equals('2026-06-01T18:00:00.000Z'));
    });

    test('encodes data as JSON string', () {
      final json = CardDraft.build()
          .title('T')
          .source('agent.t')
          .data({'score': 42, 'team': 'DEN'})()
          .toRequestJson();
      expect(json.containsKey('dataJson'), isTrue);
      expect(json['dataJson'], isA<String>());
      expect(json['dataJson'] as String, contains('"score"'));
    });

    test('encodes actions as JSON string', () {
      final action = CardAction(
        id: 'open',
        label: 'Open',
        type: CardActionType.openUrl,
        payload: 'https://example.com',
      );
      final json = CardDraft.build()
          .title('T')
          .source('agent.t')
          .actions([action])()
          .toRequestJson();
      expect(json.containsKey('actionsJson'), isTrue);
      expect(json['actionsJson'] as String, contains('"open"'));
    });
  });
}
