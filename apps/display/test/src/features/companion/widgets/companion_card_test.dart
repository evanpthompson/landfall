import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:display/src/data/companion/companion_repository.dart';
import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/companion/cubit/companion_cubit.dart';
import 'package:display/src/features/companion/widgets/companion_card.dart';
import 'package:display/src/features/companion/widgets/companion_qr_code.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCompanionRepository extends Mock implements CompanionRepository {}

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

/// Wraps CompanionCard with a pre-loaded cubit and a CompanionEventBus.
/// No CompanionPollService — polling is now handled by DisplayActionService,
/// which lives at app level and is not part of CompanionCard.
Widget _wrap({
  String displayId = 'display-abc',
  String serverUrl = 'http://localhost:8080/',
  CompanionEventBus? bus,
  Size slotSize = const Size(400, 600),
}) {
  final eventBus = bus ?? CompanionEventBus();
  final cubit = CompanionCubit(
    displayId: displayId,
    serverUrl: serverUrl,
    repository: MockCompanionRepository(),
  )..loadEntity(_entity(displayId: displayId));

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<CompanionEventBus>(create: (_) => eventBus),
    ],
    child: BlocProvider<CompanionCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: slotSize.width,
              height: slotSize.height,
              child: const CompanionCard(),
            ),
          ),
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
      // Web server runs on API port + 2 (8080 → 8082).
      expect(qr.semanticsLabel, contains(':8082/'));
    });

    testWidgets('QR URL uses webserver port (API port + 2)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(displayId: 'port-test', serverUrl: 'http://192.168.1.118:8080/'),
      );
      await tester.pump();

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.semanticsLabel, startsWith('http://192.168.1.118:8082/'));
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

    testWidgets('QR is rendered at a scannable size in a wide slot',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(slotSize: const Size(960, 540)));
      await tester.pump();

      // The white-padded Container inside CompanionQrCode is the QR badge.
      final qrBadge = find.descendant(
        of: find.byType(CompanionQrCode),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.white,
        ),
      );
      expect(qrBadge, findsOneWidget);
      final size = tester.renderObject<RenderBox>(qrBadge).size;
      expect(size.width, greaterThan(96),
          reason: 'QR must scale with the slot, not stay at the 96 px cap');
    });

    testWidgets(
        'no longer initiates its own polls — CompanionPollService absent from tree does not throw',
        (tester) async {
      // The poll service is NOT provided. CompanionCard used to look it up and
      // start its own loop; it must not do so after this refactor.
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // If CompanionCard still tried to read CompanionPollService it would throw
      // a ProviderNotFoundException. Reaching here means it does not.
      expect(find.byType(CompanionCard), findsOneWidget);
    });

    testWidgets(
        'reacts to companion kind emitted on bus.companionKinds without crash',
        (tester) async {
      final bus = CompanionEventBus();
      addTearDown(bus.dispose);

      await tester.pumpWidget(_wrap(bus: bus));
      await tester.pump();

      // Emit a web companion action kind via the app-level route.
      bus.emitCompanionKind('pet');
      await tester.pump();

      // Card must still render with no exception.
      expect(find.byType(CompanionCard), findsOneWidget);
    });
  });
}
