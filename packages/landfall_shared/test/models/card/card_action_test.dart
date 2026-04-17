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

    test('equality is value-based', () {
      const same = CardAction(
        id: 'view',
        label: 'View Details',
        type: CardActionType.openUrl,
        payload: 'https://example.com',
      );
      expect(action, equals(same));
    });
  });
}
