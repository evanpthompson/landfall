import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';

import 'package:display/src/features/settings/widgets/agent_keys_section.dart';

ApiKey _key({
  String name = 'Test Key',
  String prefix = 'lf_abc123',
  int usageCount = 12,
  int dailyLimit = 500,
  DateTime? lastUsedAt,
  String? lastUsedIp,
}) =>
    ApiKey(
      id: 1,
      name: name,
      keyHash: 'fakehash',
      prefix: prefix,
      createdAt: DateTime(2026, 5, 1),
      usageCount: usageCount,
      dailyLimit: dailyLimit,
      lastUsedAt: lastUsedAt ?? DateTime(2026, 5, 2, 10, 30),
      lastUsedIp: lastUsedIp,
      usageResetAt: DateTime(2026, 5, 3),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('AgentKeysSection', () {
    testWidgets('shows section header', (tester) async {
      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      expect(find.textContaining('AGENT KEYS', findRichText: true), findsAny);
    });

    testWidgets('shows token entry field before loading', (tester) async {
      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows Load button', (tester) async {
      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      expect(find.widgetWithText(TextButton, 'Load'), findsOneWidget);
    });

    testWidgets('shows key list after loading', (tester) async {
      final key = _key(
        name: 'Weather Agent',
        prefix: 'lf_abc123',
        lastUsedIp: '10.0.0.5',
      );

      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [key],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      // Enter token and tap Load
      await tester.enterText(find.byType(TextField), 'my-token');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.text('Weather Agent'), findsOneWidget);
    });

    testWidgets('shows prefix in key tile', (tester) async {
      final key = _key(prefix: 'lf_deadbeef');

      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [key],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'tok');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.textContaining('lf_deadbeef'), findsOneWidget);
    });

    testWidgets('shows lastUsedIp when set', (tester) async {
      final key = _key(lastUsedIp: '192.168.1.50');

      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [key],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'tok');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.textContaining('192.168.1.50'), findsOneWidget);
    });

    testWidgets('shows never used when lastUsedIp is null', (tester) async {
      final key = _key(lastUsedIp: null, lastUsedAt: null);

      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [key],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'tok');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.textContaining('never'), findsOneWidget);
    });

    testWidgets('shows usage count', (tester) async {
      final key = _key(usageCount: 42, dailyLimit: 500);

      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [key],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'tok');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.textContaining('42 / 500'), findsOneWidget);
    });

    testWidgets('shows empty state when no keys', (tester) async {
      await tester.pumpWidget(_wrap(
        AgentKeysSection(
          onListKeys: (_) async => [],
          onGenerateKey: (_, _) async => throw UnimplementedError(),
          onRevokeKey: (_, _) async => false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'tok');
      await tester.tap(find.widgetWithText(TextButton, 'Load'));
      await tester.pump();

      expect(find.textContaining('No keys'), findsOneWidget);
    });
  });
}
