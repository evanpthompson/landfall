import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/screens/photo_sources_screen.dart';

class _MockPhotoCubit extends MockCubit<PhotoState> implements PhotoCubit {}

Widget _wrap(_MockPhotoCubit cubit) => BlocProvider<PhotoCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: LandfallTheme.dark,
        home: const PhotoSourcesScreen(),
      ),
    );

void main() {
  late _MockPhotoCubit cubit;

  setUp(() {
    cubit = _MockPhotoCubit();
    when(() => cubit.state).thenReturn(const PhotoEmpty());
  });

  group('PhotoSourcesScreen', () {
    testWidgets('renders the screen title', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      expect(find.text('Photo Sources'), findsOneWidget);
    });

    testWidgets('shows Serverpod source entry', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      expect(find.text('Landfall Server'), findsOneWidget);
    });

    testWidgets('shows option to add network source', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows local directory source type option', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      // Tap add button to reveal source types
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Local Directory'), findsOneWidget);
    });

    testWidgets('shows network source type option', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Network URLs'), findsOneWidget);
    });
  });
}
