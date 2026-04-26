import 'package:test/test.dart';

import 'package:landfall_server/src/agent/card_validator.dart';
import 'package:landfall_server/src/generated/protocol.dart';

CardPushRequest _valid({
  String source = 'agent.test',
  String title = 'Test title',
  String? body,
  String? layout,
  String? priority,
  String? dataJson,
  DateTime? expiresAt,
  bool? persistent,
  String? externalId,
}) {
  return CardPushRequest(
    source: source,
    title: title,
    body: body,
    layout: layout,
    priority: priority,
    dataJson: dataJson,
    expiresAt: expiresAt,
    persistent: persistent,
    externalId: externalId,
  );
}

void main() {
  group('validateCardPushRequest', () {
    group('valid requests', () {
      test('minimal request passes', () {
        expect(validateCardPushRequest(_valid()), isEmpty);
      });

      test('full valid request passes', () {
        final errors = validateCardPushRequest(_valid(
          body: 'some body',
          layout: 'large',
          priority: 'ephemeral',
          dataJson: '{"key": "value"}',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          externalId: 'my-id',
        ));
        expect(errors, isEmpty);
      });

      test('all layout values accepted including ticker', () {
        for (final layout in ['small', 'medium', 'large', 'full', 'ticker']) {
          expect(validateCardPushRequest(_valid(layout: layout)), isEmpty,
              reason: 'layout=$layout');
        }
      });

      test('all priority values accepted', () {
        for (final priority in ['ephemeral', 'normal', 'persistent']) {
          expect(
            validateCardPushRequest(_valid(priority: priority)),
            isEmpty,
            reason: 'priority=$priority',
          );
        }
      });

      test('source without dots is accepted when matching pattern', () {
        // source must have exactly one dot
        final errors = validateCardPushRequest(_valid(source: 'a.b'));
        expect(errors, isEmpty);
      });
    });

    group('source validation', () {
      test('empty source is rejected', () {
        final errors = validateCardPushRequest(_valid(source: ''));
        expect(errors.any((e) => e.contains('source')), isTrue);
      });

      test('source without dot is rejected', () {
        final errors = validateCardPushRequest(_valid(source: 'nodot'));
        expect(errors.any((e) => e.contains('source')), isTrue);
      });

      test('source with two dots is rejected', () {
        final errors =
            validateCardPushRequest(_valid(source: 'a.b.c'));
        expect(errors.any((e) => e.contains('source')), isTrue);
      });

      test('source over max length is rejected', () {
        final longSource = 'a.${'b' * 200}';
        final errors = validateCardPushRequest(_valid(source: longSource));
        expect(errors.any((e) => e.contains('source')), isTrue);
      });

      test('source with spaces is rejected', () {
        final errors = validateCardPushRequest(_valid(source: 'agent test'));
        expect(errors.any((e) => e.contains('source')), isTrue);
      });
    });

    group('title validation', () {
      test('empty title is rejected', () {
        final errors = validateCardPushRequest(_valid(title: ''));
        expect(errors.any((e) => e.contains('title')), isTrue);
      });

      test('whitespace-only title is rejected', () {
        final errors = validateCardPushRequest(_valid(title: '   '));
        expect(errors.any((e) => e.contains('title')), isTrue);
      });

      test('title at max length passes', () {
        final errors =
            validateCardPushRequest(_valid(title: 'a' * 200));
        expect(errors, isEmpty);
      });

      test('title over max length is rejected', () {
        final errors =
            validateCardPushRequest(_valid(title: 'a' * 201));
        expect(errors.any((e) => e.contains('title')), isTrue);
      });
    });

    group('body validation', () {
      test('body at max length passes', () {
        final errors =
            validateCardPushRequest(_valid(body: 'a' * 2000));
        expect(errors, isEmpty);
      });

      test('body over max length is rejected', () {
        final errors =
            validateCardPushRequest(_valid(body: 'a' * 2001));
        expect(errors.any((e) => e.contains('body')), isTrue);
      });
    });

    group('layout validation', () {
      test('invalid layout is rejected', () {
        final errors = validateCardPushRequest(_valid(layout: 'HUGE'));
        expect(errors.any((e) => e.contains('layout')), isTrue);
      });

      test('ticker with persistent=true is rejected', () {
        final errors = validateCardPushRequest(
          _valid(layout: 'ticker', persistent: true),
        );
        expect(errors.any((e) => e.contains('ticker')), isTrue);
      });

      test('ticker with persistent=false is accepted', () {
        final errors = validateCardPushRequest(
          _valid(layout: 'ticker', persistent: false),
        );
        expect(errors, isEmpty);
      });
    });

    group('priority validation', () {
      test('invalid priority is rejected', () {
        final errors =
            validateCardPushRequest(_valid(priority: 'critical'));
        expect(errors.any((e) => e.contains('priority')), isTrue);
      });
    });

    group('dataJson validation', () {
      test('valid JSON object passes', () {
        final errors = validateCardPushRequest(
          _valid(dataJson: '{"temp": 72, "unit": "F"}'),
        );
        expect(errors, isEmpty);
      });

      test('invalid JSON is rejected', () {
        final errors =
            validateCardPushRequest(_valid(dataJson: '{not json}'));
        expect(errors.any((e) => e.contains('dataJson')), isTrue);
      });

      test('JSON array is rejected', () {
        final errors =
            validateCardPushRequest(_valid(dataJson: '[1, 2, 3]'));
        expect(errors.any((e) => e.contains('dataJson')), isTrue);
      });

      test('JSON scalar is rejected', () {
        final errors =
            validateCardPushRequest(_valid(dataJson: '"just a string"'));
        expect(errors.any((e) => e.contains('dataJson')), isTrue);
      });
    });

    group('expiresAt validation', () {
      test('future expiresAt passes', () {
        final errors = validateCardPushRequest(
          _valid(
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        );
        expect(errors, isEmpty);
      });

      test('past expiresAt is allowed (card just wont appear in listCards)',
          () {
        final errors = validateCardPushRequest(
          _valid(
            expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        );
        expect(errors, isEmpty);
      });
    });

    group('multiple errors', () {
      test('multiple violations are all reported', () {
        final errors = validateCardPushRequest(_valid(
          source: 'bad source!',
          title: '',
          layout: 'invalid',
        ));
        expect(errors.length, greaterThanOrEqualTo(3));
      });
    });
  });
}
