import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/display/remote_nav_keys.dart';

void main() {
  group('isDisplaySelectKey', () {
    test('recognizes select key down (Fire TV OK button)', () {
      expect(
        isDisplaySelectKey(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.select,
            logicalKey: LogicalKeyboardKey.select,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );
    });

    test('recognizes enter key down', () {
      expect(
        isDisplaySelectKey(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );
    });

    test('ignores key up events', () {
      expect(
        isDisplaySelectKey(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.select,
            logicalKey: LogicalKeyboardKey.select,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });

    test('ignores unrelated keys', () {
      expect(
        isDisplaySelectKey(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowDown,
            logicalKey: LogicalKeyboardKey.arrowDown,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });
  });
}
