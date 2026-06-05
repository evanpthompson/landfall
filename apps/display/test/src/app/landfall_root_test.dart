import 'package:display/src/app/landfall_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// In-memory settings repo whose stored value can be swapped between relaunches.
class _FakeSettingsRepo implements DisplaySettingsRepository {
  _FakeSettingsRepo(this.settings);

  DisplaySettings settings;

  @override
  Future<DisplaySettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(DisplaySettings s) async => settings = s;
}

Widget _harness(_FakeSettingsRepo repo) {
  return LandfallRoot(
    settingsRepository: repo,
    buildWizard: (onComplete) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: onComplete,
            child: const Text('wizard'),
          ),
        ),
      ),
    ),
    buildDisplay: (serverUrl, displayId) => MaterialApp(
      home: Scaffold(body: Center(child: Text('display:$serverUrl'))),
    ),
  );
}

void main() {
  testWidgets('shows the wizard when no server URL is configured',
      (tester) async {
    final repo = _FakeSettingsRepo(const DisplaySettings());

    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.text('wizard'), findsOneWidget);
    expect(find.textContaining('display:'), findsNothing);
  });

  testWidgets('shows the display when a URL is configured', (tester) async {
    final repo = _FakeSettingsRepo(
      const DisplaySettings(
        serverUrl: 'https://app.example.com/',
        wizardComplete: true,
        displayId: 'abc',
      ),
    );

    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.text('display:https://app.example.com/'), findsOneWidget);
  });

  testWidgets('relaunch re-reads settings and swaps wizard → display',
      (tester) async {
    final repo = _FakeSettingsRepo(const DisplaySettings());

    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();
    expect(find.text('wizard'), findsOneWidget);

    // Simulate the wizard persisting a server URL, then completing — its
    // onComplete callback is wired to LandfallRoot.relaunch.
    repo.settings = const DisplaySettings(
      serverUrl: 'https://new.example.com/',
      wizardComplete: true,
      displayId: 'abc',
    );
    await tester.tap(find.text('wizard'));
    await tester.pumpAndSettle();

    expect(find.text('display:https://new.example.com/'), findsOneWidget);
    expect(find.text('wizard'), findsNothing);
  });

  testWidgets('AppRelauncher.of lets a descendant trigger a relaunch',
      (tester) async {
    final repo = _FakeSettingsRepo(
      const DisplaySettings(
        serverUrl: 'https://old.example.com/',
        wizardComplete: true,
        displayId: 'abc',
      ),
    );

    await tester.pumpWidget(LandfallRoot(
      settingsRepository: repo,
      buildWizard: (_) => const SizedBox.shrink(),
      buildDisplay: (serverUrl, _) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppRelauncher.of(context).relaunch(),
              child: Text('display:$serverUrl'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('display:https://old.example.com/'), findsOneWidget);

    repo.settings = const DisplaySettings(
      serverUrl: 'https://changed.example.com/',
      wizardComplete: true,
      displayId: 'abc',
    );
    await tester.tap(find.text('display:https://old.example.com/'));
    await tester.pumpAndSettle();

    expect(find.text('display:https://changed.example.com/'), findsOneWidget);
  });
}
