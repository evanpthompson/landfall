import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/profile/widgets/profile_switcher.dart';

class _MockCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

// ── fixtures ──────────────────────────────────────────────────────────────────

ProfileInfo _profile(int id, String name, {bool active = false}) => ProfileInfo(
      id: id,
      name: name,
      slug: name.toLowerCase(),
      isActive: active,
      layout: DashboardLayout.weekdayLayout(),
      sortOrder: id,
    );

final _weekday = _profile(1, 'Weekday', active: true);
final _weekend = _profile(2, 'Weekend');
final _night = _profile(3, 'Night');
final _profiles = [_weekday, _weekend, _night];

// ── helpers ───────────────────────────────────────────────────────────────────

Widget _wrapSwitcher({
  required _MockCubit cubit,
  required List<ProfileInfo> profiles,
  required int activeId,
}) {
  return BlocProvider<DashboardProfileCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: ProfileSwitcher(profiles: profiles, activeId: activeId),
      ),
    ),
  );
}

Widget _wrapChip({required String name, required bool isActive, VoidCallback? onTap}) {
  return MaterialApp(
    theme: LandfallTheme.dark,
    home: Scaffold(
      body: ProfileChip(name: name, isActive: isActive, onTap: onTap),
    ),
  );
}

void main() {
  late _MockCubit cubit;

  setUp(() => cubit = _MockCubit());

  // ── ProfileSwitcher ───────────────────────────────────────────────────────────

  group('ProfileSwitcher', () {
    testWidgets('renders a chip for each profile', (tester) async {
      when(() => cubit.state)
          .thenReturn(DashboardProfileLoaded(_weekday, profiles: _profiles));

      await tester.pumpWidget(
        _wrapSwitcher(cubit: cubit, profiles: _profiles, activeId: 1),
      );

      expect(find.text('Weekday'), findsOneWidget);
      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
    });

    testWidgets('tapping an inactive chip calls activateProfile', (tester) async {
      when(() => cubit.state)
          .thenReturn(DashboardProfileLoaded(_weekday, profiles: _profiles));
      when(() => cubit.activateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrapSwitcher(cubit: cubit, profiles: _profiles, activeId: 1),
      );

      await tester.tap(find.text('Weekend'));
      await tester.pump();

      verify(() => cubit.activateProfile(2)).called(1);
    });

    testWidgets('tapping the active chip does not call activateProfile',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(DashboardProfileLoaded(_weekday, profiles: _profiles));
      when(() => cubit.activateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrapSwitcher(cubit: cubit, profiles: _profiles, activeId: 1),
      );

      await tester.tap(find.text('Weekday'));
      await tester.pump();

      verifyNever(() => cubit.activateProfile(any()));
    });

    testWidgets('renders with a single profile', (tester) async {
      when(() => cubit.state)
          .thenReturn(DashboardProfileLoaded(_weekday, profiles: [_weekday]));

      await tester.pumpWidget(
        _wrapSwitcher(cubit: cubit, profiles: [_weekday], activeId: 1),
      );

      expect(find.text('Weekday'), findsOneWidget);
      expect(find.text('Weekend'), findsNothing);
    });
  });

  // ── ProfileChip ───────────────────────────────────────────────────────────────

  group('ProfileChip', () {
    testWidgets('renders the profile name', (tester) async {
      await tester.pumpWidget(
        _wrapChip(name: 'Weekday', isActive: true, onTap: null),
      );
      expect(find.text('Weekday'), findsOneWidget);
    });

    testWidgets('calls onTap when inactive chip is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapChip(name: 'Weekend', isActive: false, onTap: () => tapped = true),
      );

      await tester.tap(find.text('Weekend'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when active chip is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        // Active chip has onTap: null — the GestureDetector ignores taps.
        _wrapChip(name: 'Weekday', isActive: true, onTap: null),
      );

      await tester.tap(find.text('Weekday'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('active chip uses accent color text', (tester) async {
      await tester.pumpWidget(
        _wrapChip(name: 'Weekday', isActive: true, onTap: null),
      );

      final text = tester.widget<Text>(find.text('Weekday'));
      expect(text.style?.color, LandfallColors.accent);
    });

    testWidgets('inactive chip uses secondary color text', (tester) async {
      await tester.pumpWidget(
        _wrapChip(name: 'Weekend', isActive: false, onTap: () {}),
      );

      final text = tester.widget<Text>(find.text('Weekend'));
      expect(text.style?.color, LandfallColors.textSecondary);
    });

    testWidgets('active chip uses bold font weight', (tester) async {
      await tester.pumpWidget(
        _wrapChip(name: 'Weekday', isActive: true, onTap: null),
      );

      final text = tester.widget<Text>(find.text('Weekday'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('inactive chip uses normal font weight', (tester) async {
      await tester.pumpWidget(
        _wrapChip(name: 'Weekend', isActive: false, onTap: () {}),
      );

      final text = tester.widget<Text>(find.text('Weekend'));
      expect(text.style?.fontWeight, FontWeight.normal);
    });
  });
}
