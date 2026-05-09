import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../web/routes/oauth_token_encryptor.dart';
import 'calendar_service.dart';

/// Fetches upcoming events from the Google Calendar API.
///
/// Configuration required in passwords.yaml:
///   googleClientId     — OAuth client ID
///   googleClientSecret — OAuth client secret
///
/// Token refresh is handled transparently: if [LinkedCredential.accessToken]
/// is expired (or within [_refreshBuffer] of expiring), a new access token is
/// fetched using the refresh token and the credential row is updated in-place.
///
/// [httpClient] is injectable for testing.
class GoogleCalendarService implements CalendarService {
  GoogleCalendarService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _calendarApiBase = 'https://www.googleapis.com/calendar/v3';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  /// How far before expiry we proactively refresh the access token.
  static const _refreshBuffer = Duration(minutes: 5);

  @override
  Future<List<CalendarEvent>> fetchUpcomingEvents(
    Session session,
    LinkedCredential credential, {
    required DateTime from,
    required DateTime to,
  }) async {
    final accessToken = await _accessToken(session, credential);
    final calendars = await _listCalendars(accessToken);
    final fetchedAt = DateTime.now().toUtc();

    final eventLists = await Future.wait(
      calendars.map(
        (cal) => _fetchEventsForCalendar(
          accessToken: accessToken,
          credentialId: credential.id!,
          calendarId: cal.id,
          calendarName: cal.name,
          from: from,
          to: to,
          fetchedAt: fetchedAt,
        ),
      ),
    );

    return eventLists.expand((e) => e).toList();
  }

  // ── Token management ─────────────────────────────���──────────────────���──────

  /// Returns a valid access token, refreshing if needed.
  Future<String> _accessToken(
    Session session,
    LinkedCredential credential,
  ) async {
    final encKey = session.passwords['oauthTokenEncryptionKey'];

    final expiresAt = credential.tokenExpiresAt;
    final needsRefresh = expiresAt == null ||
        expiresAt.isBefore(DateTime.now().toUtc().add(_refreshBuffer));

    if (!needsRefresh) {
      return OAuthTokenEncryptor.decryptIfEncrypted(
        credential.accessToken,
        encKey,
      );
    }

    final rawRefresh = credential.refreshToken;
    if (rawRefresh == null) {
      throw StateError(
        'Google credential for ${credential.providerEmail} has no refresh token.',
      );
    }
    final refreshToken =
        OAuthTokenEncryptor.decryptIfEncrypted(rawRefresh, encKey);

    final clientId = session.passwords['googleOAuthClientId'];
    final clientSecret = session.passwords['googleOAuthClientSecret'];
    if (clientId == null || clientSecret == null) {
      throw StateError(
        'googleOAuthClientId and googleOAuthClientSecret are required in passwords.yaml.',
      );
    }

    final response = await _client.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Token refresh failed for ${credential.providerEmail}: '
        '${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = json['access_token'] as String;
    final expiresIn = (json['expires_in'] as num).toInt();
    final newExpiresAt =
        DateTime.now().toUtc().add(Duration(seconds: expiresIn));

    // Persist the refreshed token (re-encrypt if key is configured).
    await LinkedCredential.db.updateRow(
      session,
      credential.copyWith(
        accessToken:
            OAuthTokenEncryptor.encryptIfKey(newAccessToken, encKey),
        tokenExpiresAt: newExpiresAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    return newAccessToken;
  }

  // ── Calendar list ──────────────────────────────────────────────────────────

  Future<List<_CalendarMeta>> _listCalendars(String accessToken) async {
    final uri = Uri.parse('$_calendarApiBase/users/me/calendarList');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'calendarList request failed: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>;

    return items
        .map((item) {
          final entry = item as Map<String, dynamic>;
          final accessRole = entry['accessRole'] as String? ?? '';
          // Skip calendars where we only have free/busy visibility.
          if (accessRole == 'freeBusyReader') return null;
          return _CalendarMeta(
            id: entry['id'] as String,
            name: (entry['summary'] as String?) ?? entry['id'] as String,
          );
        })
        .whereType<_CalendarMeta>()
        .toList();
  }

  // ── Events for one calendar ─────────────────────────────��──────────────────

  Future<List<CalendarEvent>> _fetchEventsForCalendar({
    required String accessToken,
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required DateTime from,
    required DateTime to,
    required DateTime fetchedAt,
  }) async {
    final uri = Uri.parse(
      '$_calendarApiBase/calendars/${Uri.encodeComponent(calendarId)}/events',
    ).replace(queryParameters: {
      'timeMin': from.toIso8601String(),
      'timeMax': to.toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '50',
      'fields':
          'items(id,summary,start,end,location,description,status)',
    });

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Events request failed for calendar $calendarId: '
        '${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>;

    return items
        .map((item) {
          final entry = item as Map<String, dynamic>;
          // Skip cancelled events.
          if ((entry['status'] as String?) == 'cancelled') return null;
          return _parseEvent(
            entry,
            credentialId: credentialId,
            calendarId: calendarId,
            calendarName: calendarName,
            fetchedAt: fetchedAt,
          );
        })
        .whereType<CalendarEvent>()
        .toList();
  }

  CalendarEvent _parseEvent(
    Map<String, dynamic> entry, {
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required DateTime fetchedAt,
  }) {
    final startNode = entry['start'] as Map<String, dynamic>;
    final endNode = entry['end'] as Map<String, dynamic>;

    final isAllDay = startNode.containsKey('date');

    final startTime = isAllDay
        ? _parseDate(startNode['date'] as String)
        : DateTime.parse(startNode['dateTime'] as String).toUtc();

    final endTime = isAllDay
        ? _parseDate(endNode['date'] as String)
        : DateTime.parse(endNode['dateTime'] as String).toUtc();

    return CalendarEvent(
      credentialId: credentialId,
      calendarId: calendarId,
      calendarName: calendarName,
      externalEventId: entry['id'] as String,
      title: (entry['summary'] as String?) ?? '(No title)',
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: entry['location'] as String?,
      description: entry['description'] as String?,
      fetchedAt: fetchedAt,
    );
  }

  /// Parses a Google date string "YYYY-MM-DD" to midnight UTC.
  static DateTime _parseDate(String date) {
    final parts = date.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

class _CalendarMeta {
  const _CalendarMeta({required this.id, required this.name});
  final String id;
  final String name;
}
