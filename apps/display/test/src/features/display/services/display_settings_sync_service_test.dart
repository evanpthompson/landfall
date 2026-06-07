import 'package:test/test.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/display/services/display_settings_sync_service.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeLocalRepo implements DisplaySettingsRepository {
  DisplaySettings _settings = const DisplaySettings(
    dimEnabled: true,
    dimStartHour: 22,
    dimEndHour: 7,
    dimLevel: 0.85,
    locationName: 'Local City',
    displayId: 'display-abc',
  );

  @override
  Future<DisplaySettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(DisplaySettings settings) async {
    _settings = settings;
  }
}

lf.RemoteDisplaySettings _remote({
  String displayId = 'display-abc',
  bool dimEnabled = true,
  int dimStartHour = 22,
  int dimEndHour = 7,
  double dimLevel = 0.85,
  String locationName = 'Remote City',
  String? photoSourceJson,
  DateTime? updatedAt,
}) =>
    lf.RemoteDisplaySettings(
      displayId: displayId,
      dimEnabled: dimEnabled,
      dimStartHour: dimStartHour,
      dimEndHour: dimEndHour,
      dimLevel: dimLevel,
      locationName: locationName,
      photoSourceJson: photoSourceJson,
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const displayId = 'display-abc';

  group('DisplaySettingsSyncService', () {
    test('seed-up: pushes local settings when no server row exists', () async {
      final repo = _FakeLocalRepo();
      final saved = <lf.RemoteDisplaySettings>[];

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => null,
        remoteSave: (s) async => saved.add(s),
        onApplySettings: (_) async {},
      );

      await svc.syncOnStartup();

      expect(saved.length, 1);
      expect(saved.first.displayId, displayId);
      expect(saved.first.locationName, 'Local City');
    });

    test('seed-down: applies server row when server updatedAt is newer',
        () async {
      final repo = _FakeLocalRepo();
      final applied = <DisplaySettings>[];

      final newerRemote = _remote(
        locationName: 'Remote City',
        updatedAt: DateTime(2026, 6, 1),
      );

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => newerRemote,
        remoteSave: (_) async {},
        onApplySettings: (s) async => applied.add(s),
      );

      await svc.syncOnStartup();

      expect(applied.length, 1);
      expect(applied.first.locationName, 'Remote City');
    });

    test('seed-down not applied when local updatedAt is newer', () async {
      final repo = _FakeLocalRepo();
      final applied = <DisplaySettings>[];

      // Remote row is older than anything local would be (epoch).
      final olderRemote = _remote(
        locationName: 'Old Remote City',
        updatedAt: DateTime(2020, 1, 1),
      );

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => olderRemote,
        remoteSave: (_) async {},
        onApplySettings: (s) async => applied.add(s),
        localUpdatedAt: () => DateTime(2025, 1, 1),
      );

      await svc.syncOnStartup();

      expect(applied, isEmpty);
    });

    test('pullAndApply: fetches server row and applies it locally', () async {
      final repo = _FakeLocalRepo();
      final applied = <DisplaySettings>[];

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => _remote(locationName: 'Pulled City'),
        remoteSave: (_) async {},
        onApplySettings: (s) async => applied.add(s),
      );

      await svc.pullAndApply();

      expect(applied.length, 1);
      expect(applied.first.locationName, 'Pulled City');
    });

    test('pullAndApply: no-ops when server row is absent', () async {
      final repo = _FakeLocalRepo();
      final applied = <DisplaySettings>[];

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => null,
        remoteSave: (_) async {},
        onApplySettings: (s) async => applied.add(s),
      );

      await svc.pullAndApply();

      expect(applied, isEmpty);
    });

    test('pushAsync: fires remoteSave with correct values', () async {
      final repo = _FakeLocalRepo();
      final saved = <lf.RemoteDisplaySettings>[];

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => null,
        remoteSave: (s) async => saved.add(s),
        onApplySettings: (_) async {},
      );

      const settings = DisplaySettings(
        dimEnabled: false,
        dimStartHour: 23,
        dimEndHour: 8,
        dimLevel: 0.5,
        locationName: 'Pushed City',
        displayId: displayId,
      );

      svc.pushAsync(settings);
      // Give the async fire-and-forget a moment to run.
      await Future<void>.delayed(Duration.zero);

      expect(saved.length, 1);
      expect(saved.first.locationName, 'Pushed City');
      expect(saved.first.dimEnabled, false);
    });

    test('offline-tolerant: pushAsync does not throw when remoteSave fails',
        () async {
      final repo = _FakeLocalRepo();

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => null,
        remoteSave: (_) async => throw Exception('network error'),
        onApplySettings: (_) async {},
      );

      // Should not throw.
      expect(
        () async {
          svc.pushAsync(const DisplaySettings(displayId: displayId));
          await Future<void>.delayed(Duration.zero);
        },
        returnsNormally,
      );
    });

    test('syncOnStartup: tolerates remote get failure', () async {
      final repo = _FakeLocalRepo();

      final svc = DisplaySettingsSyncService(
        displayId: displayId,
        localRepository: repo,
        remoteGet: (_) async => throw Exception('network error'),
        remoteSave: (_) async {},
        onApplySettings: (_) async {},
      );

      // Should not throw.
      await expectLater(svc.syncOnStartup(), completes);
    });
  });
}
