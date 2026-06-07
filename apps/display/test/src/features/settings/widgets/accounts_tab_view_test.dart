import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' hide LandfallTheme;

import 'package:display/src/features/settings/widgets/accounts_tab_view.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

LinkedCredentialSummary _cred({
  String provider = 'google',
  String email = 'alice@example.com',
  bool isActive = true,
}) =>
    LinkedCredentialSummary(
      id: 1,
      provider: provider,
      providerEmail: email,
      isActive: isActive,
      createdAt: DateTime(2026),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AccountsTabView', () {
    testWidgets('shows spinner while loading credentials', (tester) async {
      final completer = Completer<(List<LinkedCredentialSummary>, String)>();

      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () => completer.future,
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete so the test framework doesn't see a pending async operation.
      completer.complete((<LinkedCredentialSummary>[], 'user-id'));
    });

    testWidgets('shows error message when load fails', (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => throw Exception('network error'),
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Could not load'), findsOneWidget);
    });

    testWidgets('shows "No accounts connected yet." when credentials empty',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-123'),
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('No accounts connected yet.'), findsOneWidget);
    });

    testWidgets('shows credential email when accounts loaded', (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async =>
              ([_cred(email: 'alice@example.com')], 'uid-123'),
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shows Google Calendar and Microsoft Calendar connect tiles',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-123'),
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Microsoft Calendar'), findsOneWidget);
    });

    testWidgets('shows Copy URL button on TV (no onOpenUrl)', (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-123'),
          serverUrl: 'http://localhost:8080/',
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Copy URL'), findsWidgets);
    });

    testWidgets('shows Open button on web when onOpenUrl provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-123'),
          serverUrl: 'http://localhost:8080/',
          onOpenUrl: (url) {},
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('onOpenUrl receives correct OAuth URL when Open tapped',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-42'),
          serverUrl: 'http://localhost:8080/',
          onOpenUrl: opened.add,
        ),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open').first);
      await tester.pump();

      expect(opened.length, 1);
      expect(opened.first, contains('calendar/oauth/start'));
      expect(opened.first, contains('authUserId=uid-42'));
    });
  });
}
