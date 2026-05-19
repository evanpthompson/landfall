import 'package:flutter/services.dart';

/// Returns true when a key down event is the "OK / Select" action.
///
/// On Fire TV: the center D-pad button emits [LogicalKeyboardKey.select].
/// On desktop/keyboard: Enter is the equivalent.
bool isDisplaySelectKey(KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  final key = event.logicalKey;
  return key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter;
}
