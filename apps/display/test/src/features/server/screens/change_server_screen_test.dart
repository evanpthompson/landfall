import 'package:display/src/app/landfall_root.dart';
import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/features/server/screens/change_server_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

class _FakeHealthChecker implements ServerHealthChecker {
  _FakeHealthChecker({this.webRoutes = true});
  final bool webRoutes;
  @override
  Future<bool> isReachable(String url) async => true;
  @override
  Future<bool> servesWebRoutes(String webUrl) async => webRoutes;
}

class _FakeSettingsRepo implements DisplaySettingsRepository {
  DisplaySettings settings = const DisplaySettings(displayId: 'd1');
  @override
  Future<DisplaySettings> getSettings() async => settings;
  @override
  Future<void> saveSettings(DisplaySettings s) async => settings = s;
}

Widget _harness({
  required ServerHealthChecker health,
  required _FakeSettingsRepo repo,
  required VoidCallback onRelaunch,
  String? currentUrl,
}) {
  return MaterialApp(
    home: AppRelauncher(
      relaunch: onRelaunch,
      child: RepositoryProvider<DisplaySettingsRepository>.value(
        value: repo,
        child: ChangeServerScreen(healthChecker: health, currentUrl: currentUrl),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the current server URL when provided', (tester) async {
    await tester.pumpWidget(_harness(
      health: _FakeHealthChecker(),
      repo: _FakeSettingsRepo(),
      onRelaunch: () {},
      currentUrl: 'https://old.example.com/',
    ));

    expect(find.text('Current: https://old.example.com/'), findsOneWidget);
  });

  testWidgets('relaunches the app after a valid URL is saved', (tester) async {
    var relaunched = false;
    final repo = _FakeSettingsRepo();
    await tester.pumpWidget(_harness(
      health: _FakeHealthChecker(),
      repo: repo,
      onRelaunch: () => relaunched = true,
    ));

    await tester.enterText(find.byType(TextField), 'https://new.example.com');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(relaunched, isTrue);
    expect(repo.settings.serverUrl, 'https://new.example.com/');
    expect(repo.settings.wizardComplete, isTrue);
  });

  testWidgets('shows the wrong-origin message and does not relaunch',
      (tester) async {
    var relaunched = false;
    await tester.pumpWidget(_harness(
      health: _FakeHealthChecker(webRoutes: false),
      repo: _FakeSettingsRepo(),
      onRelaunch: () => relaunched = true,
    ));

    await tester.enterText(find.byType(TextField), 'http://192.168.1.10:8080');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(relaunched, isFalse);
    expect(find.textContaining('API port'), findsOneWidget);
  });
}
