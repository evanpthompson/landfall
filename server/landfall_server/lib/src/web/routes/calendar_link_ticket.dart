import 'package:serverpod/serverpod.dart';

/// SEC-06: short-lived, single-use tickets that carry a JWT-derived
/// `authUserId` from an authenticated RPC to the (unauthenticated, browser-
/// navigated) OAuth start routes.
///
/// A browser navigation to `/calendar/oauth/start` cannot present the
/// companion's JWT (it lives in localStorage for RPC, not as a cookie), so
/// the start route has no authenticated session. Rather than trust a
/// caller-supplied `authUserId` query parameter — which SEC-06 forbids — the
/// companion first calls an authenticated endpoint that mints a ticket bound
/// to *its own* identity. The start route then exchanges that ticket for the
/// bound `authUserId`. Tickets are single-use and expire quickly, so a leaked
/// URL cannot be replayed or used to target another user.
class CalendarLinkTicketStore {
  CalendarLinkTicketStore({
    Duration ttl = const Duration(minutes: 5),
    DateTime Function()? clock,
  })  : _ttl = ttl,
        _now = clock ?? (() => DateTime.now().toUtc());

  final Duration _ttl;
  final DateTime Function() _now;
  final Map<String, _Ticket> _tickets = {};

  /// Mints a ticket bound to [authUserId]. Returns the opaque ticket string.
  String issue(String authUserId) {
    _purgeExpired();
    final ticket = const Uuid().v4();
    _tickets[ticket] = _Ticket(authUserId, _now().add(_ttl));
    return ticket;
  }

  /// Consumes [ticket] (single-use). Returns the bound `authUserId`, or null
  /// if the ticket is unknown or expired.
  String? consume(String ticket) {
    final entry = _tickets.remove(ticket);
    if (entry == null) return null;
    if (entry.expiresAt.isBefore(_now())) return null;
    return entry.authUserId;
  }

  void _purgeExpired() {
    final now = _now();
    _tickets.removeWhere((_, v) => v.expiresAt.isBefore(now));
  }
}

class _Ticket {
  _Ticket(this.authUserId, this.expiresAt);
  final String authUserId;
  final DateTime expiresAt;
}

/// Process-wide store shared by [SettingsEndpoint.createCalendarLinkTicket]
/// (which mints) and the OAuth start routes (which consume). The API server
/// and web server run in the same Serverpod process, so a single in-memory
/// store is reachable from both.
final CalendarLinkTicketStore calendarLinkTickets = CalendarLinkTicketStore();
