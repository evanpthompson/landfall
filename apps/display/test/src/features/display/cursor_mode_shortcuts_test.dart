import 'package:display/src/features/display/cursor_mode_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCursorModeToggle', () {
    test('accepts F11 key down', () {
      expect(
        isCursorModeToggle(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.f11,
            logicalKey: LogicalKeyboardKey.f11,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );
    });

    test('ignores key up events', () {
      expect(
        isCursorModeToggle(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.f11,
            logicalKey: LogicalKeyboardKey.f11,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });

    testWidgets('accepts Ctrl+Alt+C', (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);

      expect(
        isCursorModeToggle(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyC,
            logicalKey: LogicalKeyboardKey.keyC,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );

      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });

    testWidgets('accepts Meta+Alt+C for macOS keyboards', (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);

      expect(
        isCursorModeToggle(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyC,
            logicalKey: LogicalKeyboardKey.keyC,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );

      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    });

    testWidgets('requires a modifier chord for C', (tester) async {
      expect(
        isCursorModeToggle(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyC,
            logicalKey: LogicalKeyboardKey.keyC,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });
  });
}
