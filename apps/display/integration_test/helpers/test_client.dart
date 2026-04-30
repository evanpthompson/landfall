import 'package:landfall_client/landfall_client.dart';

const _testHost = 'http://localhost:8080/';

/// Creates a Serverpod client pointed at the local integration test server.
///
/// Used in test [setUp] to push or clear seed data directly via the server API.
/// The server must be running before any test file is executed:
///
/// ```
/// cd server/landfall_server
/// dart run bin/main.dart --mode test
/// ```
Client createTestClient() => Client(_testHost);
