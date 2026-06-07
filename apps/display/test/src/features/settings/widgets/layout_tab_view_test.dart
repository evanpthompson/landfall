import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';
import 'package:display/src/features/settings/widgets/layout_tab_view.dart';

class _MockDashboardProfileCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

ProfileInfo _profile({String name = 'Default'}) => ProfileInfo(
      id: 1,
      name: name,
      slug: 'default',
      isActive: true,
      layout: DashboardLayout.defaultLayout(),
      sortOrder: 0,
    );

Widget _wrap({
  required DashboardProfileState state,
  bool leanback = false,
  ValueChanged<bool>? onMoveModeChanged,
  ValueChanged<VoidCallback>? onCancelMoveRegistered,
}) {
  final cubit = _MockDashboardProfileCubit();
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<DashboardProfileState>.value(state));

  return BlocProvider<DashboardProfileCubit>.value(
    value: cubit,
    child: MaterialApp(
      home: Scaffold(
        body: LayoutTabView(
          leanback: leanback,
          onMoveModeChanged: onMoveModeChanged,
          onCancelMoveRegistered: onCancelMoveRegistered,
        ),
      ),
    ),
  );
}

void main() {
  group('LayoutTabView', () {
    testWidgets('shows loading indicator when state is loading', (tester) async {
      await tester.pumpWidget(_wrap(state: const DashboardProfileLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LayoutEditor), findsNothing);
    });

    testWidgets('shows LayoutEditor when state is loaded', (tester) async {
      await tester.pumpWidget(
        _wrap(state: DashboardProfileLoaded(_profile())),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LayoutEditor), findsOneWidget);
    });

    testWidgets('shows Profile section header when loaded', (tester) async {
      await tester.pumpWidget(
        _wrap(state: DashboardProfileLoaded(_profile())),
      );
      await tester.pump();

      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('shows drag hint text in pointer mode (leanback: false)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          state: DashboardProfileLoaded(_profile()),
          leanback: false,
        ),
      );
      await tester.pump();

      expect(find.textContaining('DRAG TO MOVE'), findsOneWidget);
    });

    testWidgets('shows d-pad hint text in leanback mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          state: DashboardProfileLoaded(_profile()),
          leanback: true,
        ),
      );
      await tester.pump();

      expect(find.textContaining('ARROW KEYS'), findsOneWidget);
    });

    testWidgets('does not crash when state is error', (tester) async {
      await tester.pumpWidget(
        _wrap(state: const DashboardProfileError('oops')),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LayoutEditor), findsNothing);
    });
  });
}
