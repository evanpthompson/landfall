import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:landfall_shared/landfall_shared.dart';
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
    when(() => cubit.activeSource).thenReturn(const PhotoSourceServerpod());
  });

  group('PhotoSourcesScreen', () {
    testWidgets('renders the screen title', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      expect(find.text('Photo Sources'), findsOneWidget);
    });

    testWidgets('shows Serverpod source entry', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      expect(find.text('Landfall Server'), findsAtLeastNWidgets(1));
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
      expect(find.text('Local Directory'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows network source type option', (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Network URLs'), findsAtLeastNWidgets(1));
    });

    // Regression guard for the CSP egress contract: absolute URLs in
    // user-facing strings get compiled into main.dart.js, where
    // deploy/pi-gen/check-csp-egress.sh reads them as fetchable hosts the CSP
    // connect-src must allow. The dialog hint must not be URL-shaped.
    testWidgets('network URLs dialog hint contains no absolute http(s) URL',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));
      // The Network URLs source tile opens the URL-entry dialog directly.
      final tile = find.text('A list of direct image URLs');
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty);
      for (final field in fields) {
        final hint = field.decoration?.hintText ?? '';
        expect(
          RegExp(r'https?://').hasMatch(hint),
          isFalse,
          reason: 'hint "$hint" bakes a fetchable host into main.dart.js; '
              'use a non-URL placeholder (see check-csp-egress.sh)',
        );
      }
    });
  });
}
