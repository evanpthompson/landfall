import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';
import 'package:display/src/features/ticker/widgets/ticker_strip_widget.dart';

class _MockCubit extends MockCubit<TickerState> implements TickerCubit {}

Card _ticker(String msg) => Card(
      id: 't1',
      source: 'agent.claude',
      title: msg,
      layout: CardLayout.ticker,
      priority: CardPriority.ephemeral,
      persistent: false,
      createdAt: DateTime(2026),
    );

Widget _wrap(TickerState state) {
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<TickerState>.value(state));

  return BlocProvider<TickerCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: const Scaffold(
        body: Column(
          children: [
            Expanded(child: SizedBox()),
            TickerStripWidget(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('TickerStripWidget', () {
    testWidgets('renders nothing when ticker is empty', (tester) async {
      await tester.pumpWidget(_wrap(const TickerEmpty()));
      await tester.pump();

      // Empty ticker → TickerStripWidget returns SizedBox.shrink(), so no
      // ticker source label or message text should appear.
      expect(find.text('agent.claude'), findsNothing);
      expect(find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 28,
      ), findsNothing);
    });

    testWidgets('renders source and message when ticker has a message',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TickerLoaded([_ticker('Researching EV tax credits')])),
      );
      await tester.pump();

      expect(find.text('agent.claude'), findsOneWidget);
      expect(find.text('Researching EV tax credits'), findsOneWidget);

      // Drain the 8-second display cycle timer so the test ends cleanly.
      await tester.pump(const Duration(seconds: 9));
    });

    testWidgets('renders strip bar with correct height', (tester) async {
      await tester.pumpWidget(
        _wrap(TickerLoaded([_ticker('hello')])),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('hello'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxHeight, 28);

      await tester.pump(const Duration(seconds: 9));
    });
  });
}
