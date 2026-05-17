import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'google_access_token_provider.dart';
import 'photo_service.dart';

/// Lists and fetches photos from Google Drive using a service account.
///
/// Token acquisition is delegated to [GoogleAccessTokenProvider] (in
/// production, a [GoogleServiceAccountAuth] minting self-signed JWTs).
///
/// The [LinkedCredential] argument carries the synthetic row that anchors
/// [Photo.credentialId] FKs in the DB; its `accessToken` / `refreshToken`
/// fields are not consulted — the service account flow does not store
/// per-user tokens.
class GoogleDriveServiceAccountPhotoService implements PhotoService {
  GoogleDriveServiceAccountPhotoService({
    required GoogleAccessTokenProvider auth,
    http.Client? httpClient,
  })  : _auth = auth,
        _client = httpClient ?? http.Client();

  final GoogleAccessTokenProvider _auth;
  final http.Client _client;

  static const _driveApiBase = 'https://www.googleapis.com/drive/v3';

  @override
  Future<List<Photo>> listPhotos(
    Session? session,
    LinkedCredential credential,
    String folderId,
  ) async {
    final accessToken = await _auth.getAccessToken();
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
        'Drive files.list failed (service account): '
        '${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (json['files'] as List<dynamic>? ?? []);

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
    Session? session,
    LinkedCredential credential,
    String providerFileId,
  ) async {
    final accessToken = await _auth.getAccessToken();

    final uri = Uri.parse(
      '$_driveApiBase/files/${Uri.encodeComponent(providerFileId)}',
    ).replace(queryParameters: {'alt': 'media'});

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Drive file download failed for $providerFileId '
        '(service account): ${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }
}
