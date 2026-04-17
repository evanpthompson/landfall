import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_state.dart';

class MockDashboardLayoutRepository extends Mock
    implements DashboardLayoutRepository {}

void main() {
  late MockDashboardLayoutRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const DashboardLayout(id: 'fallback', name: 'Fallback', cards: []),
    );
  });

  setUp(() {
    repository = MockDashboardLayoutRepository();
  });

  group('DashboardLayoutCubit', () {
    test('initial state is DashboardLayoutLoading', () {
      final cubit = DashboardLayoutCubit(repository);
      expect(cubit.state, isA<DashboardLayoutLoading>());
    });

    group('loadLayout', () {
      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'emits [Loading, Loaded] when repository returns a layout',
        build: () {
          when(() => repository.getActiveLayout()).thenAnswer(
            (_) async => DashboardLayout.defaultLayout(),
          );
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) => cubit.loadLayout(),
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>().having(
            (s) => s.layout.name,
            'layout.name',
            'Default',
          ),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'emits [Loading, Error] when repository throws',
        build: () {
          when(() => repository.getActiveLayout())
              .thenThrow(Exception('DB error'));
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) => cubit.loadLayout(),
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutError>(),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'always emits Loading before Loaded on re-load',
        build: () {
          when(() => repository.getActiveLayout()).thenAnswer(
            (_) async => DashboardLayout.defaultLayout(),
          );
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadLayout();
          await cubit.loadLayout();
        },
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>(),
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>(),
        ],
      );
    });

    group('saveLayout', () {
      final customLayout = DashboardLayout(
        id: 'layout-custom',
        name: 'Custom',
        cards: [
          CardConfig(
            id: 'slot_clock',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
          ),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'emits Loaded with the saved layout after save succeeds',
        build: () {
          when(() => repository.getActiveLayout()).thenAnswer(
            (_) async => DashboardLayout.defaultLayout(),
          );
          when(() => repository.saveLayout(any())).thenAnswer(
            (_) async {},
          );
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadLayout();
          await cubit.saveLayout(customLayout);
        },
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>()
              .having((s) => s.layout.name, 'layout.name', 'Default'),
          isA<DashboardLayoutLoaded>()
              .having((s) => s.layout.name, 'layout.name', 'Custom'),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'does not change state if saveLayout throws',
        build: () {
          when(() => repository.getActiveLayout()).thenAnswer(
            (_) async => DashboardLayout.defaultLayout(),
          );
          when(() => repository.saveLayout(any()))
              .thenThrow(Exception('Write error'));
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadLayout();
          await cubit.saveLayout(customLayout);
        },
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>()
              .having((s) => s.layout.name, 'layout.name', 'Default'),
          // state remains Default — save failure does not overwrite
          isA<DashboardLayoutError>(),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'calls repository.saveLayout with the provided layout',
        build: () {
          when(() => repository.getActiveLayout()).thenAnswer(
            (_) async => DashboardLayout.defaultLayout(),
          );
          when(() => repository.saveLayout(any())).thenAnswer(
            (_) async {},
          );
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadLayout();
          await cubit.saveLayout(customLayout);
        },
        verify: (_) {
          verify(() => repository.saveLayout(customLayout)).called(1);
        },
      );
    });
  });
}
