import 'package:flutter/foundation.dart';

import 'package:display/src/data/companion/companion_poll_service.dart';
import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/app/poll_timeouts.dart';

/// Callback interface for reloading dashboard profiles (implemented by DashboardProfileCubit).
abstract class ProfileReloader {
  Future<void> loadProfiles();
}

/// Callback interface for reloading themes (implemented by ThemeCubit).
abstract class ThemeReloader {
  Future<void> loadThemes();
}

/// Callback interface for syncing display settings (implemented by DisplaySettingsSyncService).
abstract class SettingsReloader {
  Future<void> syncOnStartup();
  Future<void> pullAndApply();
}

/// App-level long-poll router. Owns the single companion poll loop so web
/// layout/theme edits reach the TV even when the companion card is not visible.
///
/// Replaces the per-card poll loop in CompanionCard. Route table:
///   pet / play / feed / … → CompanionEventBus.emitCompanionKind (animation)
///   layout.changed        → ProfileReloader.loadProfiles()
///   theme.changed         → ThemeReloader.loadThemes()
///   settings.changed      → SettingsReloader.pullAndApply() (no-op if not provided)
///   unknown               → ignored + debug log
class DisplayActionService {
  DisplayActionService({
    required String displayId,
    required CompanionPollService pollService,
    required CompanionEventBus bus,
    required ProfileReloader profileReloader,
    required ThemeReloader themeReloader,
    SettingsReloader? settingsReloader,
    Duration backoffDuration = const Duration(seconds: 5),
  })  : _displayId = displayId,
        _pollService = pollService,
        _bus = bus,
        _profileReloader = profileReloader,
        _themeReloader = themeReloader,
        _settingsReloader = settingsReloader,
        _backoffDuration = backoffDuration;

  final String _displayId;
  final CompanionPollService _pollService;
  final CompanionEventBus _bus;
  final ProfileReloader _profileReloader;
  final ThemeReloader _themeReloader;
  final SettingsReloader? _settingsReloader;
  final Duration _backoffDuration;

  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _loop();
  }

  void dispose() => _running = false;

  Future<void> _loop() async {
    while (_running) {
      try {
        final action = await _pollService.pollForEvents(
          _displayId,
          timeoutSeconds: kCompanionPollTimeout.inSeconds,
        );
        if (!_running) break;
        if (action == null) continue;

        switch (action.kind) {
          case 'layout.changed':
            await _profileReloader.loadProfiles();
          case 'theme.changed':
            await _themeReloader.loadThemes();
          case 'settings.changed':
            await _settingsReloader?.pullAndApply();
          default:
            // Companion animation kinds (pet, play, feed) and anything unknown.
            // Unknown kinds are silently ignored; known kinds animate the companion.
            _bus.emitCompanionKind(action.kind);
            if (_isUnknownKind(action.kind)) {
              debugPrint(
                '[DisplayActionService] unknown action kind: ${action.kind}',
              );
            }
        }
      } catch (e) {
        if (!_running) break;
        debugPrint('[DisplayActionService] poll error: $e — retrying in $_backoffDuration');
        await Future<void>.delayed(_backoffDuration);
      }
    }
  }

  static const _knownCompanionKinds = {'pet', 'play', 'feed'};

  bool _isUnknownKind(String kind) => !_knownCompanionKinds.contains(kind);
}
