import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';

void main() {
  late AppDatabase db;
  late DriftDisplaySettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftDisplaySettingsRepository(db);
  });

  tearDown(() => db.close());

  group('displayId', () {
    test('returns empty string when no settings row exists', () async {
      final settings = await repo.getSettings();
      expect(settings.displayId, isEmpty);
    });

    test('persists displayId and returns it on subsequent reads', () async {
      final id = const Uuid().v4();
      final settings = (await repo.getSettings()).copyWith(displayId: id);
      await repo.saveSettings(settings);

      final reloaded = await repo.getSettings();
      expect(reloaded.displayId, equals(id));
    });

    test('displayId is stable across multiple saves of other fields', () async {
      final id = const Uuid().v4();
      await repo.saveSettings((await repo.getSettings()).copyWith(displayId: id));

      // Update an unrelated field.
      final updated = (await repo.getSettings()).copyWith(locationName: 'London');
      await repo.saveSettings(updated);

      final reloaded = await repo.getSettings();
      expect(reloaded.displayId, equals(id));
      expect(reloaded.locationName, equals('London'));
    });

    test('two distinct UUIDs are not equal', () {
      final a = const Uuid().v4();
      final b = const Uuid().v4();
      expect(a, isNot(equals(b)));
    });

    test('UUID v4 matches expected format', () {
      final id = const Uuid().v4();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRegex.hasMatch(id), isTrue);
    });
  });
}
