import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallTheme', () {
    test('dark theme has dark brightness', () {
      expect(LandfallTheme.dark.brightness, equals(Brightness.dark));
    });

    test('dark theme uses Material 3', () {
      expect(LandfallTheme.dark.useMaterial3, isTrue);
    });

    test('scaffold background matches LandfallColors.background', () {
      expect(
        LandfallTheme.dark.scaffoldBackgroundColor,
        equals(LandfallColors.background),
      );
    });

    test('primary color matches accent', () {
      expect(
        LandfallTheme.dark.colorScheme.primary,
        equals(LandfallColors.accent),
      );
    });

    test('card color matches surface', () {
      expect(
        LandfallTheme.dark.cardTheme.color,
        equals(LandfallColors.surface),
      );
    });

    test('card has zero elevation', () {
      expect(LandfallTheme.dark.cardTheme.elevation, equals(0));
    });
  });
}
