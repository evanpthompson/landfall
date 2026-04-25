import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'photo_service.dart';

/// Lists and fetches photos from a Google Drive folder.
///
/// Configuration required in passwords.yaml:
///   googleClientId     — OAuth client ID
///   googleClientSecret — OAuth client secret
///
/// Token refresh is handled transparently before each API call.
///
/// [httpClient] is injectable for testing.
class GoogleDrivePhotoService implements PhotoService {
  GoogleDrivePhotoService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _refreshBuffer = Duration(minutes: 5);

  @override
  Future<List<Photo>> listPhotos(
    Session session,
    LinkedCredential credential,
    String folderId,
  ) async {
    final accessToken = await _accessToken(session, credential);
    final fetchedAt = DateTime.now().toUtc();

    final uri = Uri.parse('$_driveApiBase/files').replace(
      queryParameters: {
        'q': "'$folderId' in parents "
            "and mimeType contains 'image/' "
            "and trashed = false",
        'fields': 'files(id,name,mimeType)',
        'orderBy': 'name',
        'pageSize': '200',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Drive files.list failed: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final files = json['files'] as List<dynamic>;

    return files.map((item) {
      final entry = item as Map<String, dynamic>;
      return Photo(
        credentialId: credential.id!,
        providerFileId: entry['id'] as String,
        filename: (entry['name'] as String?) ?? entry['id'] as String,
        mimeType: (entry['mimeType'] as String?) ?? 'image/jpeg',
        fetchedAt: fetchedAt,
      );
    }).toList();
  }

  @override
  Future<Uint8List> fetchPhotoBytes(
    Session session,
    LinkedCredential credential,
    String providerFileId,
  ) async {
    final accessToken = await _accessToken(session, credential);

    final uri = Uri.parse(
      '$_driveApiBase/files/${Uri.encodeComponent(providerFileId)}',
    ).replace(queryParameters: {'alt': 'media'});

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Drive file download failed for $providerFileId: '
        '${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<String> _accessToken(
    Session session,
    LinkedCredential credential,
  ) async {
    final expiresAt = credential.tokenExpiresAt;
    final needsRefresh = expiresAt == null ||
        expiresAt.isBefore(DateTime.now().toUtc().add(_refreshBuffer));

    if (!needsRefresh) return credential.accessToken;

    final refreshToken = credential.refreshToken;
    if (refreshToken == null) {
      throw StateError(
        'Google credential for ${credential.providerEmail} has no refresh token.',
      );
    }

    final clientId = session.passwords['googleClientId'];
    final clientSecret = session.passwords['googleClientSecret'];
    if (clientId == null || clientSecret == null) {
      throw StateError(
        'googleClientId and googleClientSecret are required in passwords.yaml.',
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

    await LinkedCredential.db.updateRow(
      session,
      credential.copyWith(
        accessToken: newAccessToken,
        tokenExpiresAt: newExpiresAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    return newAccessToken;
  }
}
