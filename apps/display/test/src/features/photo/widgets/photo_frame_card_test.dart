import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/widgets/photo_frame_card.dart';

Widget _wrapWithState(PhotoState state, {double width = 800, double height = 600}) =>
    MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: BlocProvider<PhotoCubit>(
            create: (_) => _FakePhotoCubit(state),
            child: const PhotoFrameCard(),
          ),
        ),
      ),
    );

class _FakePhotoCubit extends PhotoCubit {
  _FakePhotoCubit(PhotoState initial) : super(_NullRepo()) {
    emit(initial);
  }
}

class _NullRepo implements PhotoRepository {
  @override
  Future<List<PhotoEntity>> getPhotos() async => [];
}

void main() {
  group('PhotoFrameCard', () {
    testWidgets('shows placeholder when loading', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoLoading()));
      expect(find.byType(PhotoFrameCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows "No photos configured" when empty', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoEmpty()));
      expect(find.text('No photos configured'), findsOneWidget);
    });

    testWidgets('shows "Photos unavailable" on error', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoError('timeout')));
      expect(find.text('Photos unavailable'), findsOneWidget);
    });

    // BUG-05: card must not overflow at small slot sizes.
    testWidgets('does not overflow in a 200x200 slot (loading)', (tester) async {
      await tester.pumpWidget(
        _wrapWithState(const PhotoLoading(), width: 200, height: 200),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow in a 200x200 slot (empty)', (tester) async {
      await tester.pumpWidget(
        _wrapWithState(const PhotoEmpty(), width: 200, height: 200),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
