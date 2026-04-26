import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';

class _MockRepo extends Mock implements CardRepository {}

Card _ticker(String id, String msg) => Card(
      id: id,
      source: 'agent.test',
      title: msg,
      layout: CardLayout.ticker,
      priority: CardPriority.ephemeral,
      persistent: false,
      createdAt: DateTime(2026),
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  TickerCubit build() => TickerCubit(repo);

  group('loadTicker', () {
    blocTest<TickerCubit, TickerState>(
      'emits TickerEmpty when buffer is empty',
      build: build,
      setUp: () {
        when(() => repo.getTickerMessages()).thenAnswer((_) async => []);
      },
      act: (c) => c.loadTicker(),
      expect: () => [const TickerEmpty()],
    );

    blocTest<TickerCubit, TickerState>(
      'emits TickerLoaded with messages when buffer has entries',
      build: build,
      setUp: () {
        when(() => repo.getTickerMessages()).thenAnswer(
          (_) async => [_ticker('1', 'Researching EV credits')],
        );
      },
      act: (c) => c.loadTicker(),
      expect: () => [
        TickerLoaded([_ticker('1', 'Researching EV credits')]),
      ],
    );

    blocTest<TickerCubit, TickerState>(
      'emits TickerEmpty on repository error',
      build: build,
      setUp: () {
        when(() => repo.getTickerMessages())
            .thenThrow(Exception('network error'));
      },
      act: (c) => c.loadTicker(),
      expect: () => [const TickerEmpty()],
    );
  });

  group('state equality', () {
    test('TickerEmpty equals TickerEmpty', () {
      expect(const TickerEmpty(), equals(const TickerEmpty()));
    });

    test('TickerLoaded equals when messages match', () {
      final a = TickerLoaded([_ticker('1', 'hello')]);
      final b = TickerLoaded([_ticker('1', 'hello')]);
      expect(a, equals(b));
    });

    test('TickerLoaded differs when messages differ', () {
      final a = TickerLoaded([_ticker('1', 'hello')]);
      final b = TickerLoaded([_ticker('1', 'world')]);
      expect(a, isNot(equals(b)));
    });
  });
}
