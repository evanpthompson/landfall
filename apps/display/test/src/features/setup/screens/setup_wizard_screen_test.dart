import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/data/discovery/mdns_server_discovery.dart';
import 'package:display/src/features/setup/cubit/setup_wizard_cubit.dart';
import 'package:display/src/features/setup/screens/setup_wizard_screen.dart';

class _MockCubit extends MockCubit<SetupWizardState>
    implements SetupWizardCubit {}

Widget _wrap(SetupWizardState state, {ValueChanged<String>? onComplete}) {
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<SetupWizardState>.value(state));

  return BlocProvider<SetupWizardCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: SetupWizardScreen(onComplete: onComplete ?? (_) {}),
    ),
  );
}

void main() {
  group('SetupWizardScreen', () {
    testWidgets('shows server URL input on serverUrl step', (tester) async {
      await tester
          .pumpWidget(_wrap(const SetupWizardAt(SetupWizardStep.serverUrl)));
      await tester.pump();

      expect(find.text('Connect to your server'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows spinner when validating', (tester) async {
      await tester.pumpWidget(_wrap(const SetupWizardValidating()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text on serverUrl error', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardStepError(
          'Could not reach the server.',
          SetupWizardStep.serverUrl,
        ),
      ));
      await tester.pump();

      expect(find.text('Could not reach the server.'), findsOneWidget);
    });

    testWidgets('shows location input on location step', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://x.com/',
        ),
      ));
      await tester.pump();

      expect(find.text('Where are you?'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('shows account info tiles on linkAccount step', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.linkAccount,
          serverUrl: 'https://x.com/',
        ),
      ));
      await tester.pump();

      expect(find.text('Connect accounts'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Agent API keys'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('shows launch button and server URL on done step',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.done,
          serverUrl: 'https://api.example.com/',
        ),
      ));
      await tester.pump();

      expect(find.text("You're all set"), findsOneWidget);
      expect(find.text('Connected to https://api.example.com/'), findsOneWidget);
      expect(find.text('Launch Landfall'), findsOneWidget);
    });

    testWidgets('step indicator renders 4 dots (discover, location, linkAccount, done)',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const SetupWizardAt(SetupWizardStep.discover)));
      await tester.pump();

      // 4 main-path steps — serverUrl is a fallback sub-step, not shown.
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('calls onComplete when SetupWizardComplete is emitted',
        (tester) async {
      String? received;
      final cubit = _MockCubit();
      const completeState =
          SetupWizardComplete(serverUrl: 'https://done.example.com/');

      when(() => cubit.state)
          .thenReturn(const SetupWizardAt(SetupWizardStep.done));
      whenListen(
        cubit,
        Stream<SetupWizardState>.fromIterable([
          const SetupWizardAt(SetupWizardStep.done),
          completeState,
        ]),
      );

      await tester.pumpWidget(
        BlocProvider<SetupWizardCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: SetupWizardScreen(onComplete: (url) => received = url),
          ),
        ),
      );
      await tester.pump();

      expect(received, 'https://done.example.com/');
    });

    testWidgets('discover step — shows scanning indicator when no servers yet',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const SetupWizardAt(SetupWizardStep.discover)));
      await tester.pump();

      expect(find.text('Find your server'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Enter manually'), findsOneWidget);
    });

    testWidgets('discover step — renders a tile for each discovered server',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SetupWizardAt(
          SetupWizardStep.discover,
          discoveredServers: const [
            DiscoveredServer(
                name: 'Landfall A', serverUrl: 'http://192.168.1.10:8080'),
            DiscoveredServer(
                name: 'Landfall B', serverUrl: 'http://192.168.1.20:8080'),
          ],
        ),
      ));
      await tester.pump();

      expect(find.text('Landfall A'), findsOneWidget);
      expect(find.text('Landfall B'), findsOneWidget);
      expect(find.text('http://192.168.1.10:8080'), findsOneWidget);
      expect(find.text('http://192.168.1.20:8080'), findsOneWidget);
    });

    testWidgets('discover step — tapping a server tile calls selectDiscoveredServer',
        (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(
        SetupWizardStep.discover,
        discoveredServers: [
          DiscoveredServer(
              name: 'Landfall A', serverUrl: 'http://192.168.1.10:8080'),
        ],
      );
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<SetupWizardState>.value(state));
      when(() => cubit.selectDiscoveredServer(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: SetupWizardScreen(onComplete: (_) {}),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Landfall A'));
      await tester.pump();

      verify(() => cubit.selectDiscoveredServer('http://192.168.1.10:8080'))
          .called(1);
    });

    testWidgets('discover step — tapping Enter manually calls skipDiscovery',
        (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(SetupWizardStep.discover);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<SetupWizardState>.value(state));
      when(() => cubit.skipDiscovery()).thenReturn(null);

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: SetupWizardScreen(onComplete: (_) {}),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Enter manually'));
      await tester.pump();

      verify(() => cubit.skipDiscovery()).called(1);
    });
  });
}
