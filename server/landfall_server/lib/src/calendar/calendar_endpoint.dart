import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class CalendarEndpoint extends Endpoint {
  Future<List<CalendarEvent>> getUpcomingEvents(Session session) async {
    _requireAuth(session);
    const clampedLimit = 20;
    final now = DateTime.now().toUtc();

    return CalendarEvent.db.find(
      session,
      where: (t) => t.startTime > now,
      orderBy: (t) => t.startTime,
      orderDescending: false,
      limit: clampedLimit,
    );
  }

  void _requireAuth(Session session) {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
  }
}
