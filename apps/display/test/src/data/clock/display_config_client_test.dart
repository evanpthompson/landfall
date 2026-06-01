import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:display/src/data/clock/display_config_client.dart';

class _FakeConfigClient implements DisplayConfigClient {
  _FakeConfigClient(this._name);
  final String? _name;
  @override
  Future<String?> fetchTimezone() async => _name;
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('resolveServerTimezone', () {
    test('returns the matching Location for a valid zone name', () async {
      final loc = await resolveServerTimezone(
        _FakeConfigClient('America/Chicago'),
      );
      expect(loc, isNotNull);
      expect(loc!.name, 'America/Chicago');
    });

    test('returns null when the server reports no timezone', () async {
      expect(await resolveServerTimezone(_FakeConfigClient(null)), isNull);
      expect(await resolveServerTimezone(_FakeConfigClient('')), isNull);
    });

    test('returns null for an unknown zone name (does not throw)', () async {
      final loc = await resolveServerTimezone(
        _FakeConfigClient('Mars/Olympus_Mons'),
        // Force the production lookup path (which throws on unknown names).
        lookup: tz.getLocation,
      );
      expect(loc, isNull);
    });
  });
}
