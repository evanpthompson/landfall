import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/settings/widgets/web_display_tab.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

lf.RemoteDisplaySettings _settings({
  bool dimEnabled = true,
  int dimStartHour = 22,
  int dimEndHour = 7,
  double dimLevel = 0.85,
  String locationName = 'Test City',
  String? photoSourceJson,
}) =>
    lf.RemoteDisplaySettings(
      displayId: 'display-abc',
      dimEnabled: dimEnabled,
      dimStartHour: dimStartHour,
      dimEndHour: dimEndHour,
      dimLevel: dimLevel,
      locationName: locationName,
      photoSourceJson: photoSourceJson,
      updatedAt: DateTime(2026),
    );

String _sourceJson(PhotoSource source) => jsonEncode(source.toJson());

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.dark(surface: LandfallColors.surface),
      ),
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 900,
          child: child,
        ),
      ),
    );

Future<void> _pumpTab(
  WidgetTester tester, {
  Future<lf.RemoteDisplaySettings?> Function()? onLoad,
  Future<void> Function(lf.RemoteDisplaySettings)? onSave,
  void Function(String)? onPush,
}) async {
  await tester.pumpWidget(
    _wrap(
      WebDisplayTab(
        displayId: 'display-abc',
        onLoad: onLoad ?? () async => _settings(),
        onSave: onSave ?? (_) async {},
        onPush: onPush ?? (_) {},
      ),
    ),
  );
}

const _saveKey = Key('web_display_save');

Future<void> _scrollToSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_saveKey));
  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('WebDisplayTab', () {
    testWidgets('shows loading indicator while onLoad is pending',
        (tester) async {
      final completer = Completer<lf.RemoteDisplaySettings?>();
      await _pumpTab(tester, onLoad: () => completer.future);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Complete to avoid pending-timer assertion.
      completer.complete(_settings());
      await tester.pumpAndSettle();
    });

    testWidgets('shows form fields after load completes', (tester) async {
      await _pumpTab(tester);
      await tester.pumpAndSettle();

      // SectionHeader uppercases titles.
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('DIM'), findsOneWidget);
      expect(find.text('PHOTO SOURCE'), findsOneWidget);
      await _scrollToSave(tester);
      expect(find.byKey(_saveKey), findsOneWidget);
    });

    testWidgets('location field pre-filled from loaded settings',
        (tester) async {
      await _pumpTab(
        tester,
        onLoad: () async => _settings(locationName: 'Portland'),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Portland'), findsOneWidget);
    });

    testWidgets('dim switch reflects loaded dimEnabled value', (tester) async {
      await _pumpTab(
        tester,
        onLoad: () async => _settings(dimEnabled: false),
      );
      await tester.pumpAndSettle();
      final sw = tester.widget<Switch>(find.byType(Switch).first);
      expect(sw.value, isFalse);
    });

    testWidgets('save button calls onSave with updated location',
        (tester) async {
      final saved = <lf.RemoteDisplaySettings>[];
      await _pumpTab(tester, onSave: (s) async => saved.add(s));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test City'),
        'New City',
      );
      await _scrollToSave(tester);
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(saved.length, 1);
      expect(saved.first.locationName, 'New City');
    });

    testWidgets('save calls onPush with settings.changed on success',
        (tester) async {
      final pushed = <String>[];
      await _pumpTab(tester, onPush: pushed.add);
      await tester.pumpAndSettle();

      await _scrollToSave(tester);
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(pushed, contains('settings.changed'));
    });

    testWidgets('save does not call onPush when onSave throws', (tester) async {
      final pushed = <String>[];
      await _pumpTab(
        tester,
        onSave: (_) async => throw Exception('server error'),
        onPush: pushed.add,
      );
      await tester.pumpAndSettle();

      await _scrollToSave(tester);
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(pushed, isEmpty);
    });

    testWidgets('shows error message when onLoad throws', (tester) async {
      await _pumpTab(
        tester,
        onLoad: () async => throw Exception('network error'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load'), findsOneWidget);
    });

    group('photo source — Landfall Server', () {
      testWidgets('info button opens bottom sheet explaining Google Drive',
          (tester) async {
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(const PhotoSourceServerpod()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.textContaining('Google Drive'), findsWidgets);
      });

      testWidgets('no URL field shown for Landfall Server source',
          (tester) async {
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(const PhotoSourceServerpod()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('photo_source_network_urls')), findsNothing);
      });
    });

    group('photo source — Network URLs', () {
      testWidgets('URL field shown when Network URLs source selected',
          (tester) async {
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(
              const PhotoSourceNetwork(
                urls: ['https://example.com/a.jpg'],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('photo_source_network_urls')),
          findsOneWidget,
        );
      });

      testWidgets('save encodes network URLs into photoSourceJson',
          (tester) async {
        final saved = <lf.RemoteDisplaySettings>[];
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(
              const PhotoSourceNetwork(urls: ['https://old.com/img.jpg']),
            ),
          ),
          onSave: (s) async => saved.add(s),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('photo_source_network_urls')),
          'https://new.com/a.jpg\nhttps://new.com/b.jpg',
        );
        await _scrollToSave(tester);
        await tester.tap(find.byKey(_saveKey));
        await tester.pumpAndSettle();

        expect(saved.length, 1);
        final json =
            jsonDecode(saved.first.photoSourceJson!) as Map<String, dynamic>;
        final source = PhotoSource.fromJson(json) as PhotoSourceNetwork;
        expect(source.urls,
            containsAll(['https://new.com/a.jpg', 'https://new.com/b.jpg']));
      });

      testWidgets('save disabled when URL list is empty', (tester) async {
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(
              const PhotoSourceNetwork(urls: ['https://example.com/img.jpg']),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('photo_source_network_urls')),
          '',
        );
        await tester.pump();

        await _scrollToSave(tester);
        final saveButton = tester.widget<ElevatedButton>(
          find.byKey(_saveKey),
        );
        expect(saveButton.onPressed, isNull);
      });
    });

    group('photo source — read-only sources', () {
      testWidgets('local_directory source shows read-only notice',
          (tester) async {
        await _pumpTab(
          tester,
          onLoad: () async => _settings(
            photoSourceJson: _sourceJson(
              const PhotoSourceLocalDirectory(path: '/home/pi/photos'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('device'), findsOneWidget);
      });

      testWidgets('null photoSourceJson defaults to Landfall Server',
          (tester) async {
        await _pumpTab(tester, onLoad: () async => _settings());
        await tester.pumpAndSettle();
        expect(find.text('Landfall Server'), findsOneWidget);
        expect(find.byKey(const Key('photo_source_network_urls')), findsNothing);
      });
    });
  });
}
