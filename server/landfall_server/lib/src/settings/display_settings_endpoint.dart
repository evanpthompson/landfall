import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

void _requireAuth(Session session) {
  if (session.authenticated == null) {
    throw LandfallException(message: 'Authentication required.');
  }
}

/// Provides remote read/write access to a display's user-configurable settings.
///
/// All methods require an authenticated session.
/// One row per displayId — last-write-wins by updatedAt.
class DisplaySettingsEndpoint extends Endpoint {
  /// Returns the remote settings record for [displayId], or null when no
  /// record exists yet (display has not yet seeded its settings to the server).
  Future<RemoteDisplaySettings?> get(
    Session session,
    String displayId,
  ) async {
    _requireAuth(session);
    return RemoteDisplaySettings.db.findFirstRow(
      session,
      where: (t) => t.displayId.equals(displayId),
    );
  }

  /// Upserts the settings record for the given [settings.displayId].
  ///
  /// Bumps [RemoteDisplaySettings.updatedAt] to now() server-side so that
  /// last-write-wins resolution always uses a monotonically-increasing server
  /// clock rather than a client clock.
  Future<void> save(
    Session session,
    RemoteDisplaySettings settings,
  ) async {
    _requireAuth(session);
    final now = DateTime.now().toUtc();
    final existing = await RemoteDisplaySettings.db.findFirstRow(
      session,
      where: (t) => t.displayId.equals(settings.displayId),
    );
    if (existing == null) {
      await RemoteDisplaySettings.db.insertRow(
        session,
        RemoteDisplaySettings(
          displayId: settings.displayId,
          dimEnabled: settings.dimEnabled,
          dimStartHour: settings.dimStartHour,
          dimEndHour: settings.dimEndHour,
          dimLevel: settings.dimLevel,
          locationName: settings.locationName,
          photoSourceJson: settings.photoSourceJson,
          updatedAt: now,
        ),
      );
    } else {
      await RemoteDisplaySettings.db.updateRow(
        session,
        existing.copyWith(
          dimEnabled: settings.dimEnabled,
          dimStartHour: settings.dimStartHour,
          dimEndHour: settings.dimEndHour,
          dimLevel: settings.dimLevel,
          locationName: settings.locationName,
          photoSourceJson: settings.photoSourceJson,
          updatedAt: now,
        ),
      );
    }
  }
}
