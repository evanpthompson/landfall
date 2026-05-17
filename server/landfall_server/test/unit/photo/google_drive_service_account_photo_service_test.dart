import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

import 'package:landfall_server/src/photo/google_access_token_provider.dart';
import 'package:landfall_server/src/photo/google_drive_service_account_photo_service.dart';
import 'package:landfall_server/src/generated/protocol.dart';

/// Returns a fixed token without ever touching the network.
class _FakeProvider implements GoogleAccessTokenProvider {
  _FakeProvider([this.token = 'ya29.fake']);
  final String token;
  int callCount = 0;

  @override
  Future<String> getAccessToken() async {
    callCount++;
    return token;
  }
}

class _StubClient extends http.BaseClient {
  _StubClient(this.responder);
  final FutureOr<http.Response> Function(http.Request) responder;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final captured = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..body = body;
    requests.add(captured);
    final response = await responder(captured);
    // Use the response's raw bytes (not body) so callers can return binary
    // content like image bytes without UTF-8 corruption.
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

/// Builds a [LinkedCredential] with the minimum surface the service touches.
LinkedCredential _serviceAccountCredential({int id = 42}) {
  return LinkedCredential(
    id: id,
    authUserId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
    provider: 'google-sa',
    providerEmail: 'svc@x.iam.gserviceaccount.com',
    accessToken: '',
    isActive: true,
    createdAt: DateTime.utc(2026, 5, 17),
    updatedAt: DateTime.utc(2026, 5, 17),
  );
}

void main() {
  group('GoogleDriveServiceAccountPhotoService.listPhotos', () {
    test('queries Drive with the right q, returns parsed Photo rows',
        () async {
      final client = _StubClient((req) {
        expect(req.method, 'GET');
        expect(req.url.path, '/drive/v3/files');
        expect(req.url.queryParameters['q'],
            "'folder-abc' in parents and mimeType contains 'image/' and trashed = false");
        expect(req.headers['Authorization'], 'Bearer ya29.fake');
        return http.Response(
          jsonEncode({
            'files': [
              {'id': 'a', 'name': 'one.jpg', 'mimeType': 'image/jpeg'},
              {'id': 'b', 'name': 'two.png', 'mimeType': 'image/png'},
            ],
          }),
          200,
        );
      });

      final service = GoogleDriveServiceAccountPhotoService(
        auth: _FakeProvider(),
        httpClient: client,
      );
      final photos = await service.listPhotos(
        null, // Session ignored by the SA implementation
        _serviceAccountCredential(id: 7),
        'folder-abc',
      );

      expect(photos, hasLength(2));
      expect(photos[0].providerFileId, 'a');
      expect(photos[0].filename, 'one.jpg');
      expect(photos[0].mimeType, 'image/jpeg');
      expect(photos[0].credentialId, 7);
      expect(photos[1].providerFileId, 'b');
    });

    test('throws on non-200 with the status code in the message', () async {
      final client = _StubClient((_) => http.Response(
            jsonEncode({'error': {'message': 'forbidden'}}),
            403,
          ));
      final service = GoogleDriveServiceAccountPhotoService(
        auth: _FakeProvider(),
        httpClient: client,
      );
      await expectLater(
        service.listPhotos(null, _serviceAccountCredential(), 'folder-abc'),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            allOf(contains('403'), contains('Drive')))),
      );
    });

    test('passes the access token from the provider as Bearer auth', () async {
      final provider = _FakeProvider('ya29.specific');
      final client = _StubClient((req) {
        expect(req.headers['Authorization'], 'Bearer ya29.specific');
        return http.Response(jsonEncode({'files': []}), 200);
      });
      final service = GoogleDriveServiceAccountPhotoService(
        auth: provider,
        httpClient: client,
      );
      await service.listPhotos(null, _serviceAccountCredential(), 'f');
      expect(provider.callCount, 1);
    });
  });

  group('GoogleDriveServiceAccountPhotoService.fetchPhotoBytes', () {
    test('GETs the right URL with alt=media and returns raw bytes', () async {
      final imageBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00];
      final client = _StubClient((req) {
        expect(req.method, 'GET');
        expect(req.url.path, '/drive/v3/files/file-xyz');
        expect(req.url.queryParameters['alt'], 'media');
        expect(req.headers['Authorization'], 'Bearer ya29.fake');
        return http.Response.bytes(imageBytes, 200);
      });

      final service = GoogleDriveServiceAccountPhotoService(
        auth: _FakeProvider(),
        httpClient: client,
      );
      final bytes = await service.fetchPhotoBytes(
        null,
        _serviceAccountCredential(),
        'file-xyz',
      );
      expect(bytes, equals(imageBytes));
    });

    test('throws when Drive returns non-200', () async {
      final client = _StubClient((_) => http.Response('not found', 404));
      final service = GoogleDriveServiceAccountPhotoService(
        auth: _FakeProvider(),
        httpClient: client,
      );
      await expectLater(
        service.fetchPhotoBytes(null, _serviceAccountCredential(), 'x'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('404'),
        )),
      );
    });

    test('URL-encodes the providerFileId so special characters are safe',
        () async {
      final client = _StubClient((req) {
        expect(req.url.path, '/drive/v3/files/${Uri.encodeComponent("a/b c")}');
        return http.Response('', 200);
      });
      final service = GoogleDriveServiceAccountPhotoService(
        auth: _FakeProvider(),
        httpClient: client,
      );
      await service.fetchPhotoBytes(null, _serviceAccountCredential(), 'a/b c');
    });
  });
}
