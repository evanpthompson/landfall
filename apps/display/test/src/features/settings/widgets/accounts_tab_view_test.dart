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

    testWidgets('Open mints a ticket and opens the ticket URL (no authUserId)',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-42'),
          serverUrl: 'http://localhost:8080/',
          webServerUrl: 'http://localhost:8082/',
          onOpenUrl: opened.add,
          onCreateLinkTicket: () async => 'ticket-abc',
        ),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open').first);
      await tester.pump();
      await tester.pump();

      expect(opened.length, 1);
      expect(opened.first, contains('calendar/oauth/start'));
      // SEC-06: identity rides in the ticket, never the URL.
      expect(opened.first, contains('ticket=ticket-abc'));
      expect(opened.first, isNot(contains('authUserId')));
    });

    testWidgets('OAuth connect URL uses webServerUrl, not the API serverUrl',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-42'),
          serverUrl: 'http://localhost:8080/',
          webServerUrl: 'http://localhost:8082/',
          onOpenUrl: opened.add,
          onCreateLinkTicket: () async => 'ticket-abc',
        ),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open').first);
      await tester.pump();
      await tester.pump();

      expect(opened.length, 1);
      // OAuth routes are registered on the Serverpod web server (8082), not
      // the API server (8080). The connect URL must target the web server.
      expect(
        opened.first,
        startsWith('http://localhost:8082/calendar/oauth/start'),
      );
    });

    testWidgets('webServerUrl defaults to serverUrl when omitted',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-42'),
          serverUrl: 'http://localhost:8082/',
          onOpenUrl: opened.add,
          onCreateLinkTicket: () async => 'ticket-abc',
        ),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open').first);
      await tester.pump();
      await tester.pump();

      expect(
        opened.first,
        startsWith('http://localhost:8082/calendar/oauth/start'),
      );
    });

    testWidgets('connect buttons are disabled without a ticket minter',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AccountsTabView(
          onLoad: () async => (<LinkedCredentialSummary>[], 'uid-42'),
          serverUrl: 'http://localhost:8082/',
          onOpenUrl: (_) {},
          // no onCreateLinkTicket
        ),
      ));
      await tester.pump();
      await tester.pump();

      final openButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Open').first,
          matching: find.byType(OutlinedButton),
        ).first,
      );
      expect(openButton.onPressed, isNull);
    });
  });
}
