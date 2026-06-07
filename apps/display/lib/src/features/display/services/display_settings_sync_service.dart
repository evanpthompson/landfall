import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';

/// Synchronises display settings between the local Drift store and the server.
///
/// Conflict policy: **last write wins by updatedAt**. The server always stamps
/// `updatedAt` with the server clock on save, so TV-local writes and web writes
/// both produce monotonically-increasing timestamps.
///
/// Usage:
///   - Call [syncOnStartup] once at app start after the client is ready.
///   - Call [pushAsync] (fire-and-forget) after every TV-local settings save.
///   - Call [pullAndApply] when a `settings.changed` action arrives.
class DisplaySettingsSyncService {
  DisplaySettingsSyncService({
    required String displayId,
    required DisplaySettingsRepository localRepository,
    required Future<lf.RemoteDisplaySettings?> Function(String displayId)
        remoteGet,
    required Future<void> Function(lf.RemoteDisplaySettings settings)
        remoteSave,
    required Future<void> Function(DisplaySettings settings) onApplySettings,
    DateTime Function()? localUpdatedAt,
  })  : _displayId = displayId,
        _local = localRepository,
        _remoteGet = remoteGet,
        _remoteSave = remoteSave,
        _onApplySettings = onApplySettings,
        _localUpdatedAt = localUpdatedAt ?? (() => DateTime.fromMillisecondsSinceEpoch(0));

  final String _displayId;
  final DisplaySettingsRepository _local;
  final Future<lf.RemoteDisplaySettings?> Function(String) _remoteGet;
  final Future<void> Function(lf.RemoteDisplaySettings) _remoteSave;
  Future<void> Function(DisplaySettings) _onApplySettings;
  final DateTime Function() _localUpdatedAt;

  /// Replaces the apply-settings callback. Call once the BLoC tree is ready
  /// so remote pulls can notify running cubits.
  set onApplySettings(Future<void> Function(DisplaySettings) fn) =>
      _onApplySettings = fn;

  /// Compares local and server state.
  ///
  /// If no server row exists → seed-up (push local to server).
  /// If server `updatedAt` is newer → seed-down (apply server to local).
  /// Otherwise → no-op (local is up to date).
  Future<void> syncOnStartup() async {
    try {
      final remote = await _remoteGet(_displayId);
      if (remote == null) {
        // No server row yet — seed up.
        final local = await _local.getSettings();
        await _pushSettings(local);
      } else if (remote.updatedAt.isAfter(_localUpdatedAt())) {
        // Server is newer — seed down.
        await _applyRemote(remote);
      }
    } catch (_) {
      // Offline or server error — local remains source of truth.
    }
  }

  /// Fire-and-forget write-through: saves [settings] to the server.
  ///
  /// Errors are swallowed — the local Drift write has already succeeded and the
  /// TV remains functional offline. The next successful sync will reconcile.
  void pushAsync(DisplaySettings settings) {
    _pushSettings(settings).ignore();
  }

  /// Fetches the latest server state and applies it locally.
  ///
  /// Called when a `settings.changed` action arrives from the long-poll loop.
  /// No-ops if the server row is absent (e.g. race with a first-boot seed).
  Future<void> pullAndApply() async {
    try {
      final remote = await _remoteGet(_displayId);
      if (remote == null) return;
      await _applyRemote(remote);
    } catch (_) {
      // Offline — stay with current local state.
    }
  }

  Future<void> _pushSettings(DisplaySettings s) async {
    await _remoteSave(
      lf.RemoteDisplaySettings(
        displayId: _displayId,
        dimEnabled: s.dimEnabled,
        dimStartHour: s.dimStartHour,
        dimEndHour: s.dimEndHour,
        dimLevel: s.dimLevel,
        locationName: s.locationName,
        photoSourceJson: s.photoSourceJson,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _applyRemote(lf.RemoteDisplaySettings r) async {
    final updated = DisplaySettings(
      dimEnabled: r.dimEnabled,
      dimStartHour: r.dimStartHour,
      dimEndHour: r.dimEndHour,
      dimLevel: r.dimLevel,
      locationName: r.locationName,
      photoSourceJson: r.photoSourceJson,
    );
    await _local.saveSettings(updated);
    await _onApplySettings(updated);
  }
}
