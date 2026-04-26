import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/cards/cubit/card_state.dart';
import 'package:display/src/features/cards/widgets/card_action_button.dart';

class _MockCardCubit extends MockCubit<CardState> implements CardCubit {}

Card _card({List<CardAction>? actions}) => Card(
      id: 'card-1',
      source: 'agent.test',
      title: 'Test card',
      layout: CardLayout.medium,
      priority: CardPriority.normal,
      persistent: false,
      createdAt: DateTime(2026),
      actions: actions,
    );

Widget _wrap(Widget child, CardCubit cubit) {
  return BlocProvider<CardCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  late _MockCardCubit cubit;

  setUp(() {
    cubit = _MockCardCubit();
    when(() => cubit.state).thenReturn(const CardLoading());
  });

  setUpAll(() {
    registerFallbackValue(const CardLoading());
  });

  group('CardActionButton', () {
    testWidgets('renders label text', (tester) async {
      const action = CardAction(
        id: 'dismiss',
        label: 'Dismiss',
        type: CardActionType.dismiss,
      );

      await tester.pumpWidget(_wrap(
        CardActionButton(card: _card(), action: action),
        cubit,
      ));

      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('dismiss action calls cubit.dismissCard', (tester) async {
      when(() => cubit.dismissCard(any())).thenAnswer((_) async {});

      const action = CardAction(
        id: 'dismiss',
        label: 'Dismiss',
        type: CardActionType.dismiss,
      );

      await tester.pumpWidget(_wrap(
        CardActionButton(card: _card(), action: action),
        cubit,
      ));

      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      verify(() => cubit.dismissCard('card-1')).called(1);
    });

    testWidgets('requireConfirm shows dialog before executing', (tester) async {
      when(() => cubit.dismissCard(any())).thenAnswer((_) async {});

      const action = CardAction(
        id: 'dismiss',
        label: 'Dismiss',
        type: CardActionType.dismiss,
        requireConfirm: true,
      );

      await tester.pumpWidget(_wrap(
        CardActionButton(card: _card(), action: action),
        cubit,
      ));

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // cubit should NOT have been called yet
      verifyNever(() => cubit.dismissCard(any()));
    });

    testWidgets('confirm dialog — cancel does not call cubit', (tester) async {
      when(() => cubit.dismissCard(any())).thenAnswer((_) async {});

      const action = CardAction(
        id: 'dismiss',
        label: 'Dismiss',
        type: CardActionType.dismiss,
        requireConfirm: true,
      );

      await tester.pumpWidget(_wrap(
        CardActionButton(card: _card(), action: action),
        cubit,
      ));

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.dismissCard(any()));
    });

    testWidgets('confirm dialog — confirm calls cubit.dismissCard',
        (tester) async {
      when(() => cubit.dismissCard(any())).thenAnswer((_) async {});

      const action = CardAction(
        id: 'dismiss',
        label: 'Remove',
        type: CardActionType.dismiss,
        requireConfirm: true,
      );

      await tester.pumpWidget(_wrap(
        CardActionButton(card: _card(), action: action),
        cubit,
      ));

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => cubit.dismissCard('card-1')).called(1);
    });
  });
}
