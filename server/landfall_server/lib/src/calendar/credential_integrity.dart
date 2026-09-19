import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// The RFC 4122 shape the `uuid` package demands when Serverpod deserializes a
/// `UuidValue` column — version nibble 0–8, variant nibble 8/9/a/b.
///
/// Postgres stores any 32 hex digits in a `uuid` column, so a value that fails
/// this check can sit on disk perfectly happily and then throw
/// `FormatException` the moment Dart reads the row. One such row makes the
/// *whole* query throw, which is why a single bad credential took down
/// `SettingsEndpoint.getLinkedCredentials` and every account's calendar
/// refresh on 2026-05-03.
///
/// The same string is used for the Dart check and the Postgres `~*` filter so
/// the two can never drift apart.
const uuidRfc4122Pattern =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

final _uuidRegExp = RegExp(uuidRfc4122Pattern, caseSensitive: false);

/// Whether [value] is a UUID Serverpod can deserialize into a `UuidValue`.
bool isDeserializableUuid(String value) => _uuidRegExp.hasMatch(value);

/// Result of sorting `(id, authUserId)` rows by whether Dart can read them.
typedef CredentialPartition = ({List<int> readable, List<int> unreadable});

/// Splits raw `(id, authUserId::text)` rows into ids that deserialize and ids
/// that do not.
///
/// A row with a null id cannot be addressed at all, so it is dropped from both
/// lists; a row with a null UUID is counted as unreadable so it still gets
/// logged.
CredentialPartition partitionCredentialRows(Iterable<List<dynamic>> rows) {
  final readable = <int>[];
  final unreadable = <int>[];

  for (final row in rows) {
    final id = row.isNotEmpty ? row[0] : null;
    if (id is! int) continue;
    final rawUuid = row.length > 1 ? row[1] : null;
    if (rawUuid is String && isDeserializableUuid(rawUuid)) {
      readable.add(id);
    } else {
      unreadable.add(id);
    }
  }

  return (readable: readable, unreadable: unreadable);
}

/// The id-and-uuid query the readable-credential read runs before the typed
/// one. Kept as a function so the `isActive` clause is covered by a test
/// rather than by reading the string.
String credentialIdQuery({required bool activeOnly}) =>
    'SELECT id, "authUserId"::text FROM calendar_linked_credentials'
    '${activeOnly ? ' WHERE "isActive" = true' : ''}';

/// Linked credentials, with rows Dart cannot deserialize left out.
///
/// Degrades by returning fewer rows, never by widening what is accepted: a
/// corrupt row is skipped and logged loudly rather than being allowed to abort
/// the read for every other account. The row is left on disk — repairing it
/// needs a human who knows which user it belonged to.
///
/// [activeOnly] false is for callers that must see disabled rows too, such as
/// the one-shot token encryption migration.
Future<List<LinkedCredential>> findReadableCredentials(
  Session session, {
  bool activeOnly = true,
  Column Function(LinkedCredentialTable)? orderBy,
}) async {
  final rows = await session.db.unsafeQuery(
    credentialIdQuery(activeOnly: activeOnly),
  );

  final partition = partitionCredentialRows(rows.map((r) => r.toList()));

  if (partition.unreadable.isNotEmpty) {
    session.log(
      'Skipped ${partition.unreadable.length} calendar credential row(s) whose '
      'authUserId is not an RFC 4122 UUID and therefore cannot be read: ids '
      '${partition.unreadable.join(', ')}. Repair or delete these rows — they '
      'are invisible to every calendar feature until then.',
      level: LogLevel.warning,
    );
  }

  if (partition.readable.isEmpty) return const [];

  return LinkedCredential.db.find(
    session,
    where: (t) => t.id.inSet(partition.readable.toSet()),
    orderBy: orderBy,
  );
}
