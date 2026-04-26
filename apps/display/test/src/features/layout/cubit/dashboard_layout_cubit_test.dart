import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_state.dart';

class MockDashboardLayoutRepository extends Mock
    implements DashboardLayoutRepository {}

final _weekdayLayout = DashboardLayout.weekdayLayout();
final _weekendLayout = DashboardLayout.weekendLayout();
final _allPresets = [_weekdayLayout, _weekendLayout, DashboardLayout.nightLayout()];

void main() {
  late MockDashboardLayoutRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const DashboardLayout(id: 'fallback', name: 'Fallback', cards: []),
    );
  });

  setUp(() {
    repository = MockDashboardLayoutRepository();
    when(() => repository.getAllLayouts())
        .thenAnswer((_) async => _allPresets);
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
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) => cubit.loadLayout(),
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>().having(
            (s) => s.layout.presetType,
            'presetType',
            LayoutPresetType.weekday,
          ),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'Loaded state carries allLayouts from repository',
        build: () {
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) => cubit.loadLayout(),
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>().having(
            (s) => s.allLayouts.length,
            'allLayouts.length',
            3,
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
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
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
        name: 'My Custom',
        presetType: LayoutPresetType.custom,
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
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          when(() => repository.saveLayout(any()))
              .thenAnswer((_) async {});
          return DashboardLayoutCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadLayout();
          await cubit.saveLayout(customLayout);
        },
        expect: () => [
          isA<DashboardLayoutLoading>(),
          isA<DashboardLayoutLoaded>()
              .having((s) => s.layout.presetType, 'presetType',
                  LayoutPresetType.weekday),
          isA<DashboardLayoutLoaded>()
              .having((s) => s.layout.name, 'name', 'My Custom'),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'emits Error if saveLayout throws',
        build: () {
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
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
          isA<DashboardLayoutLoaded>(),
          isA<DashboardLayoutError>(),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'calls repository.saveLayout with the provided layout',
        build: () {
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          when(() => repository.saveLayout(any()))
              .thenAnswer((_) async {});
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

    group('switchPreset', () {
      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'switches to weekend layout and emits Loaded with weekend preset',
        build: () {
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          when(() => repository.setActiveLayout(any()))
              .thenAnswer((_) async {});
          return DashboardLayoutCubit(repository);
        },
        seed: () => DashboardLayoutLoaded(_weekdayLayout,
            allLayouts: _allPresets),
        act: (cubit) async {
          // After switchPreset, getActiveLayout returns the weekend layout.
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekendLayout);
          await cubit.switchPreset(LayoutPresetType.weekend);
        },
        expect: () => [
          isA<DashboardLayoutLoaded>().having(
            (s) => s.layout.presetType,
            'presetType',
            LayoutPresetType.weekend,
          ),
        ],
      );

      blocTest<DashboardLayoutCubit, DashboardLayoutState>(
        'emits Error when setActiveLayout throws',
        build: () {
          when(() => repository.getActiveLayout())
              .thenAnswer((_) async => _weekdayLayout);
          when(() => repository.setActiveLayout(any()))
              .thenThrow(Exception('Network error'));
          return DashboardLayoutCubit(repository);
        },
        seed: () => DashboardLayoutLoaded(_weekdayLayout,
            allLayouts: _allPresets),
        act: (cubit) => cubit.switchPreset(LayoutPresetType.weekend),
        expect: () => [isA<DashboardLayoutError>()],
      );
    });
  });
}
