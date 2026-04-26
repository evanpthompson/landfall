import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('CardAction', () {
    const action = CardAction(
      id: 'view',
      label: 'View Details',
      type: CardActionType.openUrl,
      payload: 'https://example.com',
    );

    test('toJson includes all fields', () {
      final json = action.toJson();
      expect(json['id'], 'view');
      expect(json['label'], 'View Details');
      expect(json['type'], 'openUrl');
      expect(json['payload'], 'https://example.com');
    });

    test('fromJson roundtrip preserves all fields', () {
      final roundtripped = CardAction.fromJson(action.toJson());
      expect(roundtripped, equals(action));
    });

    test('toJson omits payload when null', () {
      const noPayload = CardAction(
        id: 'dismiss',
        label: 'Dismiss',
        type: CardActionType.dismiss,
      );
      expect(noPayload.toJson().containsKey('payload'), isFalse);
    });

    test('requireConfirm defaults to false', () {
      expect(action.requireConfirm, isFalse);
    });

    test('toJson omits requireConfirm when false', () {
      expect(action.toJson().containsKey('requireConfirm'), isFalse);
    });

    test('toJson includes requireConfirm when true', () {
      const confirmAction = CardAction(
        id: 'buy',
        label: 'Confirm Purchase',
        type: CardActionType.webhook,
        payload: 'https://hooks.example.com/buy',
        requireConfirm: true,
      );
      expect(confirmAction.toJson()['requireConfirm'], isTrue);
    });

    test('fromJson roundtrip preserves requireConfirm', () {
      const confirmAction = CardAction(
        id: 'buy',
        label: 'Confirm Purchase',
        type: CardActionType.webhook,
        requireConfirm: true,
      );
      final roundtripped = CardAction.fromJson(confirmAction.toJson());
      expect(roundtripped.requireConfirm, isTrue);
    });

    test('fromJson defaults requireConfirm to false when absent', () {
      final json = {'id': 'x', 'label': 'X', 'type': 'dismiss'};
      expect(CardAction.fromJson(json).requireConfirm, isFalse);
    });

    test('equality is value-based', () {
      const same = CardAction(
        id: 'view',
        label: 'View Details',
        type: CardActionType.openUrl,
        payload: 'https://example.com',
      );
      expect(action, equals(same));
    });

    test('instances differing only in requireConfirm are not equal', () {
      const withConfirm = CardAction(
        id: 'view',
        label: 'View Details',
        type: CardActionType.openUrl,
        payload: 'https://example.com',
        requireConfirm: true,
      );
      expect(action, isNot(equals(withConfirm)));
    });
  });
}
