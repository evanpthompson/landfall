import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../web/routes/oauth_token_encryptor.dart';
import 'calendar_service.dart';

/// Fetches upcoming events from the Microsoft Graph Calendar API.
///
/// Configuration required in passwords.yaml:
///   microsoftClientId     — Azure app client ID
///   microsoftClientSecret — Azure app client secret
///
/// Token refresh is handled transparently: if [LinkedCredential.accessToken]
/// is expired (or within [_refreshBuffer] of expiring), a new access token is
/// fetched using the refresh token and the credential row is updated in-place.
///
/// [httpClient] is injectable for testing.
class MicrosoftCalendarService implements CalendarService {
  MicrosoftCalendarService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _graphApiBase = 'https://graph.microsoft.com/v1.0';
  static const _tokenEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';

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

  // ── Token management ──────────────────────────────────────────────────────

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
        'Microsoft credential for ${credential.providerEmail} has no refresh token.',
      );
    }
    final refreshToken =
        OAuthTokenEncryptor.decryptIfEncrypted(rawRefresh, encKey);

    final clientId = session.passwords['microsoftClientId'];
    final clientSecret = session.passwords['microsoftClientSecret'];
    if (clientId == null || clientSecret == null) {
      throw StateError(
        'microsoftClientId and microsoftClientSecret are required in passwords.yaml.',
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
        'scope': 'Calendars.Read offline_access',
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

  // ── Calendar list ─────────────────────────────────────────────────────────

  Future<List<_CalendarMeta>> _listCalendars(String accessToken) async {
    final uri = Uri.parse('$_graphApiBase/me/calendars');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'calendars request failed: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['value'] as List<dynamic>;

    return items.map((item) {
      final entry = item as Map<String, dynamic>;
      return _CalendarMeta(
        id: entry['id'] as String,
        name: (entry['name'] as String?) ?? entry['id'] as String,
      );
    }).toList();
  }

  // ── Events for one calendar ───────────────────────────────────────────────

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
      '$_graphApiBase/me/calendars/${Uri.encodeComponent(calendarId)}/calendarView',
    ).replace(queryParameters: {
      'startDateTime': from.toIso8601String(),
      'endDateTime': to.toIso8601String(),
      '\$select': 'id,subject,start,end,isAllDay,location,body',
      '\$top': '50',
    });

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Prefer': 'outlook.timezone="UTC"',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'calendarView request failed for calendar $calendarId: '
        '${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['value'] as List<dynamic>;

    return items.map((item) {
      final entry = item as Map<String, dynamic>;
      return _parseEvent(
        entry,
        credentialId: credentialId,
        calendarId: calendarId,
        calendarName: calendarName,
        fetchedAt: fetchedAt,
      );
    }).toList();
  }

  CalendarEvent _parseEvent(
    Map<String, dynamic> entry, {
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required DateTime fetchedAt,
  }) {
    final isAllDay = (entry['isAllDay'] as bool?) ?? false;

    final startNode = entry['start'] as Map<String, dynamic>;
    final endNode = entry['end'] as Map<String, dynamic>;

    // With the Prefer: outlook.timezone="UTC" header, Graph returns all times
    // in UTC. All-day events have midnight UTC times.
    final startTime = DateTime.parse(
      startNode['dateTime'] as String,
    ).toUtc();
    final endTime = DateTime.parse(
      endNode['dateTime'] as String,
    ).toUtc();

    final locationNode = entry['location'] as Map<String, dynamic>?;
    final location =
        locationNode?['displayName'] as String?;

    final bodyNode = entry['body'] as Map<String, dynamic>?;
    final description = bodyNode?['content'] as String?;

    return CalendarEvent(
      credentialId: credentialId,
      calendarId: calendarId,
      calendarName: calendarName,
      externalEventId: entry['id'] as String,
      title: (entry['subject'] as String?) ?? '(No title)',
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: (location?.isNotEmpty ?? false) ? location : null,
      description: (description?.isNotEmpty ?? false) ? description : null,
      fetchedAt: fetchedAt,
    );
  }
}

class _CalendarMeta {
  const _CalendarMeta({required this.id, required this.name});
  final String id;
  final String name;
}
