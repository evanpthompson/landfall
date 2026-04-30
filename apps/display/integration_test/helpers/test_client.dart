import 'package:landfall_client/landfall_client.dart';

const _testHost = 'http://localhost:8080/';

/// Creates a Serverpod client pointed at the local integration test server.
///
/// Used in test [setUp] to push or clear seed data directly via the server API.
/// The server must be running in development mode before any test file runs:
///
/// ```
/// cd server/landfall_server
/// dart run bin/main.dart --apply-migrations
/// ```
Client createTestClient() => Client(_testHost);
