import 'package:flutter/services.dart';

/// Returns true when a key down event should toggle cursor mode.
///
/// F11 is convenient on Linux kiosks. Ctrl+Alt+C is easier to reach on compact
/// keyboards and Option+Command+C avoids conflicts with macOS fullscreen keys.
bool isCursorModeToggle(KeyEvent event) {
  if (event is! KeyDownEvent) return false;

  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.f11) return true;

  final pressed = HardwareKeyboard.instance.logicalKeysPressed;
  final hasAlt =
      pressed.contains(LogicalKeyboardKey.altLeft) ||
      pressed.contains(LogicalKeyboardKey.altRight);
  final hasControl =
      pressed.contains(LogicalKeyboardKey.controlLeft) ||
      pressed.contains(LogicalKeyboardKey.controlRight);
  final hasMeta =
      pressed.contains(LogicalKeyboardKey.metaLeft) ||
      pressed.contains(LogicalKeyboardKey.metaRight);

  return key == LogicalKeyboardKey.keyC && hasAlt && (hasControl || hasMeta);
}
