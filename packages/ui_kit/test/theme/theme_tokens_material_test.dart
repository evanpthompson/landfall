import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallThemeTokensX.toMaterialThemeData()', () {
    test('scaffoldBackgroundColor matches backgroundValue token', () {
      final tokens = LandfallThemeTokens.defaults()
          .copyWith(backgroundValue: '#112233');
      final theme = tokens.toMaterialThemeData();
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF112233)));
    });

    test('colorScheme.surface matches cardFill token', () {
      final tokens = LandfallThemeTokens.defaults()
          .copyWith(cardFill: '#AABBCC');
      final theme = tokens.toMaterialThemeData();
      expect(theme.colorScheme.surface, equals(const Color(0xFFAABBCC)));
    });

    test('colorScheme.onSurface matches colorTextPrimary token', () {
      final tokens = LandfallThemeTokens.defaults()
          .copyWith(colorTextPrimary: '#EEEEEE');
      final theme = tokens.toMaterialThemeData();
      expect(theme.colorScheme.onSurface, equals(const Color(0xFFEEEEEE)));
    });

    test('colorScheme.primary matches colorAccent token', () {
      final tokens = LandfallThemeTokens.defaults()
          .copyWith(colorAccent: '#FF5500');
      final theme = tokens.toMaterialThemeData();
      expect(theme.colorScheme.primary, equals(const Color(0xFFFF5500)));
    });

    test('brightness is dark', () {
      final theme = LandfallThemeTokens.defaults().toMaterialThemeData();
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('accent token change produces different primary color', () {
      final themeA = LandfallThemeTokens.defaults()
          .copyWith(colorAccent: '#FF0000')
          .toMaterialThemeData();
      final themeB = LandfallThemeTokens.defaults()
          .copyWith(colorAccent: '#0000FF')
          .toMaterialThemeData();
      expect(themeA.colorScheme.primary, isNot(equals(themeB.colorScheme.primary)));
    });
  });
}
