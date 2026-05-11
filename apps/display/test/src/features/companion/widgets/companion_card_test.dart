import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:display/src/data/companion/companion_poll_service.dart';
import 'package:display/src/data/companion/companion_repository.dart';
import 'package:display/src/features/companion/cubit/companion_cubit.dart';
import 'package:display/src/features/companion/widgets/companion_card.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCompanionRepository extends Mock implements CompanionRepository {}
class MockCompanionPollService extends Mock implements CompanionPollService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CompanionEntity _entity({String displayId = 'display-abc'}) => CompanionEntity(
      id: '1',
      displayId: displayId,
      seed: 1,
      rarityTier: RarityTier.uncommon,
      speciesId: 'lumen',
      name: 'Lumen',
      traits: [PersonalityTrait.curious],
      evolutionStage: 0,
      createdAt: DateTime(2026, 5, 1),
      assetCredit: '@credit',
    );

/// Wraps CompanionCard with a pre-loaded cubit and a non-blocking poll service.
Widget _wrap({
  String displayId = 'display-abc',
  String serverUrl = 'http://localhost:8080/',
  CompanionPollService? pollService,
}) {
  final poll = pollService ?? MockCompanionPollService();

  // Return a future that never completes (no timer created — safe in fakeAsync).
  when(() => poll.pollForEvents(
        any(),
        timeoutSeconds: any(named: 'timeoutSeconds'),
      )).thenAnswer((_) => Completer<lf.CompanionAction?>().future);

  final cubit = CompanionCubit(
    displayId: displayId,
    serverUrl: serverUrl,
    repository: MockCompanionRepository(),
  )..loadEntity(_entity(displayId: displayId));

  return RepositoryProvider<CompanionPollService>(
    create: (_) => poll,
    child: BlocProvider<CompanionCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, height: 600, child: CompanionCard()),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CompanionCard', () {
    testWidgets('renders creature name when entity is loaded', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Lumen'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders rarity badge', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Uncommon'), findsOneWidget);
    });

    testWidgets('renders QR code widget', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('QR data URL contains display ID and companion path',
        (tester) async {
      await tester.pumpWidget(
        _wrap(displayId: 'my-uuid', serverUrl: 'http://localhost:8080/'),
      );
      await tester.pump();

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.semanticsLabel, contains('my-uuid'));
      expect(qr.semanticsLabel, contains('/c/'));
    });

    test('kindToState maps pet → pet animation', () {
      expect(CompanionCard.kindToState('pet'), CompanionAnimationState.pet);
    });

    test('kindToState maps play → play animation', () {
      expect(CompanionCard.kindToState('play'), CompanionAnimationState.play);
    });

    test('kindToState maps feed → reactCelebratory', () {
      expect(
        CompanionCard.kindToState('feed'),
        CompanionAnimationState.reactCelebratory,
      );
    });

    test('kindToState falls back to idle for unknown kinds', () {
      expect(
        CompanionCard.kindToState('unknown'),
        CompanionAnimationState.idle,
      );
    });
  });
}
