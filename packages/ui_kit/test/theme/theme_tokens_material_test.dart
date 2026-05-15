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

  // For each registry family, toMaterialThemeData() should:
  //   (a) apply the canonical family name to the textTheme (via fontFamily: param,
  //       not via GoogleFonts.getTextTheme), so bodyMedium.fontFamily == name.
  //   (b) NOT produce a 'packages/google_fonts/...' prefix, which signals that
  //       the GoogleFonts path was taken instead of the bundled-asset path.
  group('font resolution — all registry families resolve and are treated as bundled', () {
    void expectBundled(String token, String expectedFamily) {
      final theme = LandfallThemeTokens.defaults()
          .copyWith(fontFamily: token)
          .toMaterialThemeData();
      final bodyFamily = theme.textTheme.bodyMedium?.fontFamily;
      expect(bodyFamily, equals(expectedFamily),
          reason: 'token "$token" should resolve to "$expectedFamily"');
      expect(bodyFamily, isNot(contains('packages/google_fonts')),
          reason: 'bundled family should not route through GoogleFonts package path');
    }

    test('inter', () => expectBundled('inter', 'Inter'));
    test('inter mixed-case', () => expectBundled('Inter', 'Inter'));
    test('roboto', () => expectBundled('roboto', 'Roboto'));

    test('dm sans', () => expectBundled('dm sans', 'DM Sans'));
    test('dm_sans', () => expectBundled('dm_sans', 'DM Sans'));
    test('space grotesk', () => expectBundled('space grotesk', 'Space Grotesk'));
    test('space_grotesk', () => expectBundled('space_grotesk', 'Space Grotesk'));
    test('jetbrains mono', () => expectBundled('jetbrains mono', 'JetBrains Mono'));
    test('jetbrains_mono', () => expectBundled('jetbrains_mono', 'JetBrains Mono'));
    test('playfair display', () => expectBundled('playfair display', 'Playfair Display'));
    test('playfair_display', () => expectBundled('playfair_display', 'Playfair Display'));
    test('space mono', () => expectBundled('space mono', 'Space Mono'));
    test('space_mono', () => expectBundled('space_mono', 'Space Mono'));
    test('bebas neue', () => expectBundled('bebas neue', 'Bebas Neue'));
    test('bebas_neue', () => expectBundled('bebas_neue', 'Bebas Neue'));

    test('lexend', () => expectBundled('lexend', 'Lexend'));
    test('lora', () => expectBundled('lora', 'Lora'));
    test('orbitron', () => expectBundled('orbitron', 'Orbitron'));
    test('outfit', () => expectBundled('outfit', 'Outfit'));
    test('syne', () => expectBundled('syne', 'Syne'));
  });

  group('font resolution — system / empty / unknown yield no custom fontFamily', () {
    // When no fontFamily is resolved, toMaterialThemeData() passes fontFamily:null
    // to ThemeData, so the textTheme is identical to the bare dark ThemeData default.
    final defaultBodyFamily =
        ThemeData.dark(useMaterial3: true).textTheme.bodyMedium?.fontFamily;

    void expectNoCustomFont(String token) {
      final theme = LandfallThemeTokens.defaults()
          .copyWith(fontFamily: token)
          .toMaterialThemeData();
      expect(theme.textTheme.bodyMedium?.fontFamily, equals(defaultBodyFamily),
          reason: 'token "$token" should not inject a custom fontFamily');
    }

    test('system', () => expectNoCustomFont('system'));
    test('empty string', () => expectNoCustomFont(''));
    test('unknown token', () => expectNoCustomFont('wingdings'));
  });
}
