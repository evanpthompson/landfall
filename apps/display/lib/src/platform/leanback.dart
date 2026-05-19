import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the app should render its TV / 10-foot UX (large focus rings,
/// D-pad-friendly traversal, on-screen keyboard helpers).
///
/// Resolution order:
///   1. `--dart-define=LANDFALL_LEANBACK=true|false` if set wins outright,
///      so a release APK can lock its mode and tests can pin behavior.
///   2. On Android, ask `UiModeManager` (via the `landfall/leanback` method
///      channel) whether the device reports `UI_MODE_TYPE_TELEVISION`.
///   3. Anything else (macOS, Linux, iOS, web, or Android with a channel
///      error) → false. Touch UX is the default.
class Leanback {
  /// Production constructor — reads the dart-define and queries the live
  /// platform channel.
  Leanback()
      : _isAndroid = !kIsWeb && Platform.isAndroid,
        _override = _envOverride,
        _probe = _defaultProbe;

  /// Test seam. Lets tests bypass `dart:io` and the platform channel by
  /// injecting the platform flag and the channel probe directly.
  @visibleForTesting
  Leanback.test({
    required bool isAndroid,
    bool? override,
    Future<bool?> Function()? probe,
  })  : _isAndroid = isAndroid,
        _override = override,
        _probe = probe ?? _defaultProbe;

  final bool _isAndroid;
  final bool? _override;
  final Future<bool?> Function() _probe;

  Future<bool> isLeanback() async {
    if (_override != null) return _override;
    if (!_isAndroid) return false;
    try {
      return (await _probe()) ?? false;
    } catch (_) {
      return false;
    }
  }

  static const _hasEnv = bool.hasEnvironment('LANDFALL_LEANBACK');
  static const _envValue = bool.fromEnvironment('LANDFALL_LEANBACK');
  static bool? get _envOverride => _hasEnv ? _envValue : null;
}

const _channel = MethodChannel('landfall/leanback');

Future<bool?> _defaultProbe() => _channel.invokeMethod<bool>('isTelevision');
