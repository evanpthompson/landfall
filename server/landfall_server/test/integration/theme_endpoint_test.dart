import 'dart:convert';

import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _minimalValid = '''
version: "1.0"
meta:
  name: "Test Theme"
  description: "A theme created in tests."
''';

const _invalidYaml = '''
version: "2.0"
meta:
  name: "Bad Theme"
''';

const _fullValid = '''
version: "1.0"
meta:
  name: "Neon Test"
  author: "tester"
  description: "Neon theme for tests."
  tags: [test, neon]
surface:
  background:
    type: solid
    value: "#050508"
  card:
    fill: "rgba(255, 255, 255, 0.04)"
    border:
      color: "rgba(0, 255, 180, 0.3)"
      width: 1.5
      style: solid
    radius: 4
    blur: 0
    shadow: none
color:
  accent: "#00FFB4"
animation:
  transition: fade
  speed: fast
  cardEntry: scale
  tickerScroll: fast
''';

void main() {
  withServerpod('Given ThemeEndpoint', (sessionBuilder, endpoints) {
    group('listThemes', () {
      test('returns at least the built-in themes', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes, isNotEmpty);
      });

      test('built-in themes include default-dark', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes.any((t) => t.slug == 'default-dark'), isTrue);
      });

      test('built-in themes include default-light', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes.any((t) => t.slug == 'default-light'), isTrue);
      });

      test('all returned themes have non-empty slugs and names', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        for (final t in themes) {
          expect(t.slug, isNotEmpty, reason: 'slug must not be empty');
          expect(t.name, isNotEmpty, reason: 'name must not be empty');
        }
      });

      test('all returned themes have non-empty resolvedJson', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        for (final t in themes) {
          expect(t.resolvedJson, isNotEmpty,
              reason: 'resolvedJson must not be empty for ${t.slug}');
        }
      });

      test('built-in themes have isBuiltIn = true', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final builtIns = themes.where((t) => t.isBuiltIn);
        expect(builtIns, isNotEmpty);
        for (final t in builtIns) {
          expect(t.isBuiltIn, isTrue);
        }
      });
    });

    group('uploadTheme', () {
      test('valid YAML stores and returns the theme', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        expect(result.theme, isNotNull);
        expect(result.errors, isEmpty);
        expect(result.theme!.name, equals('Test Theme'));
      });

      test('uploaded theme has assigned id', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        expect(result.theme!.id, isNotNull);
      });

      test('uploaded theme appears in listThemes', () async {
        await endpoints.theme.uploadTheme(sessionBuilder, _fullValid);
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes.any((t) => t.name == 'Neon Test'), isTrue);
      });

      test('uploaded theme has isBuiltIn = false', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        expect(result.theme!.isBuiltIn, isFalse);
      });

      test('uploaded theme has non-empty resolvedJson', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        expect(result.theme!.resolvedJson, isNotEmpty);
      });

      test('invalid YAML returns validation errors without storing', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _invalidYaml);
        expect(result.theme, isNull);
        expect(result.errors, isNotEmpty);
      });

      test('validation errors include token path and message', () async {
        final result =
            await endpoints.theme.uploadTheme(sessionBuilder, _invalidYaml);
        expect(result.errors.first.tokenPath, isNotEmpty);
        expect(result.errors.first.message, isNotEmpty);
      });

      test('re-uploading same slug replaces the existing theme', () async {
        await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes.where((t) => t.name == 'Test Theme'), hasLength(1));
      });
    });

    group('deleteTheme', () {
      test('deletes an imported theme by id', () async {
        final upload =
            await endpoints.theme.uploadTheme(sessionBuilder, _minimalValid);
        final id = upload.theme!.id!;

        await endpoints.theme.deleteTheme(sessionBuilder, id);

        final themes = await endpoints.theme.listThemes(sessionBuilder);
        expect(themes.any((t) => t.id == id), isFalse);
      });

      test('throws when attempting to delete a built-in theme', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final builtIn = themes.firstWhere((t) => t.isBuiltIn);

        expect(
          () => endpoints.theme.deleteTheme(sessionBuilder, builtIn.id!),
          throwsA(anything),
        );
      });

      test('is a no-op for unknown id', () async {
        await endpoints.theme.deleteTheme(sessionBuilder, 999999);
        // Should not throw.
      });
    });

    group('previewTheme', () {
      test('returns resolved token JSON for a valid theme id', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final theme = themes.first;

        final json =
            await endpoints.theme.previewTheme(sessionBuilder, theme.id!);
        expect(json, isNotEmpty);
      });

      test('resolved token JSON includes color.accent key', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final theme = themes.first;

        final json =
            await endpoints.theme.previewTheme(sessionBuilder, theme.id!);
        final tokens = jsonDecode(json) as Map<String, dynamic>;
        expect(tokens.containsKey('color.accent'), isTrue);
      });

      test('throws for unknown theme id', () async {
        expect(
          () => endpoints.theme.previewTheme(sessionBuilder, 999999),
          throwsA(anything),
        );
      });
    });

    group('applyTheme', () {
      late DashboardProfile profile;

      setUp(() async {
        profile = await endpoints.profile.createProfile(
          sessionBuilder,
          'Theme Test Profile',
        );
      });

      test('links a theme to a profile', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final theme = themes.first;

        await endpoints.theme.applyTheme(
          sessionBuilder,
          theme.id!,
          profileId: profile.id!,
        );

        final profiles = await endpoints.profile.listProfiles(sessionBuilder);
        final updated = profiles.firstWhere((p) => p.id == profile.id);
        expect(updated.themeId, equals(theme.slug));
      });

      test('applies theme globally when profileId is null', () async {
        final themes = await endpoints.theme.listThemes(sessionBuilder);
        final theme = themes.first;

        // Should not throw even without a profileId.
        await endpoints.theme.applyTheme(sessionBuilder, theme.id!);
      });

      test('throws for unknown theme id', () async {
        expect(
          () => endpoints.theme.applyTheme(
            sessionBuilder,
            999999,
            profileId: profile.id!,
          ),
          throwsA(anything),
        );
      });
    });
  });
}
