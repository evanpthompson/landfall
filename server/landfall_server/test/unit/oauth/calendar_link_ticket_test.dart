import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/calendar_link_ticket.dart';

void main() {
  group('CalendarLinkTicketStore', () {
    test('issued ticket resolves to the bound authUserId', () {
      final store = CalendarLinkTicketStore();
      const uid = '00000000-0000-4000-8000-100000000001';

      final ticket = store.issue(uid);

      expect(ticket, isNotEmpty);
      expect(store.consume(ticket), equals(uid));
    });

    test('is single-use — a consumed ticket cannot be replayed', () {
      final store = CalendarLinkTicketStore();
      final ticket = store.issue('uid-a');

      expect(store.consume(ticket), 'uid-a');
      expect(store.consume(ticket), isNull, reason: 'replay must fail');
    });

    test('unknown ticket resolves to null', () {
      final store = CalendarLinkTicketStore();
      expect(store.consume('never-issued'), isNull);
    });

    test('expired ticket resolves to null and is not honoured', () {
      var now = DateTime.utc(2026, 1, 1, 12);
      final store = CalendarLinkTicketStore(
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );
      final ticket = store.issue('uid-b');

      now = now.add(const Duration(minutes: 6));
      expect(store.consume(ticket), isNull);
    });

    test('distinct issues produce distinct tickets bound to their own user', () {
      final store = CalendarLinkTicketStore();
      final a = store.issue('uid-a');
      final b = store.issue('uid-b');

      expect(a, isNot(equals(b)));
      expect(store.consume(b), 'uid-b');
      expect(store.consume(a), 'uid-a');
    });
  });
}
