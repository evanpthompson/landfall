// ignore_for_file: deprecated_member_use

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'calendar_service.dart';
import 'google_calendar_service.dart';
import 'microsoft_calendar_service.dart';

const _refreshInterval = Duration(minutes: 15);

/// Periodically fetches upcoming calendar events for all active credentials
/// and caches them in the [CalendarEvent] table.
///
/// One refresh run processes every active [LinkedCredential] in sequence.
/// A failure on one credential is logged and skipped — other credentials
/// continue unaffected.
///
/// Registered with Serverpod as 'calendarRefresh'. Self-rescheduling pattern
/// mirrors [WeatherRefreshCall].
class CalendarRefreshCall extends FutureCall<SerializableModel> {
  /// How far ahead to fetch events.
  static const _lookAhead = Duration(days: 14);

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await _refreshAll(session);
    } catch (e, stackTrace) {
      session.log(
        'Calendar refresh failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      await session.serverpod.futureCallWithDelay(
        'calendarRefresh',
        null,
        _refreshInterval,
      );
    }
  }

  Future<void> _refreshAll(Session session) async {
    final credentials = await LinkedCredential.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    if (credentials.isEmpty) return;

    final now = DateTime.now().toUtc();
    final windowEnd = now.add(_lookAhead);

    for (final credential in credentials) {
      await _refreshCredential(session, credential, now, windowEnd);
    }
  }

  Future<void> _refreshCredential(
    Session session,
    LinkedCredential credential,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final service = _serviceFor(credential);
      final events = await service.fetchUpcomingEvents(
        session,
        credential,
        from: from,
        to: to,
      );

      // Deduplicate by externalEventId — Google can return the same event
      // from multiple calendar feeds within one credential.
      final seen = <String>{};
      final unique =
          events.where((e) => seen.add(e.externalEventId)).toList();

      // Replace all cached events for this credential atomically.
      await session.db.transaction((tx) async {
        await CalendarEvent.db.deleteWhere(
          session,
          where: (t) => t.credentialId.equals(credential.id!),
          transaction: tx,
        );
        if (unique.isNotEmpty) {
          await CalendarEvent.db.insert(session, unique, transaction: tx);
        }
      });

      session.log(
        'Calendar refresh: ${unique.length} events for '
        '${credential.provider}:${credential.providerEmail}',
      );
    } catch (e, stackTrace) {
      session.log(
        'Calendar refresh failed for '
        '${credential.provider}:${credential.providerEmail}: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Maps a credential's provider string to the correct [CalendarService].
  CalendarService _serviceFor(LinkedCredential credential) {
    return switch (credential.provider) {
      'google' => GoogleCalendarService(),
      'microsoft' => MicrosoftCalendarService(),
      _ => throw UnimplementedError(
          'Calendar provider "${credential.provider}" is not yet supported.',
        ),
    };
  }
}
