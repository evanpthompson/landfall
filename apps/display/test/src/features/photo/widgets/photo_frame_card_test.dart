import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/widgets/photo_frame_card.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {
  @override
  String? get currentAccessToken => null;
}

Widget _wrapWithState(
  PhotoState state, {
  double width = 800,
  double height = 600,
}) {
  final authCubit = MockAuthCubit();
  when(() => authCubit.state).thenReturn(const AuthUnauthenticated());
  return MaterialApp(
    theme: LandfallTheme.dark,
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PhotoCubit>(create: (_) => _FakePhotoCubit(state)),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const PhotoFrameCard(),
        ),
      ),
    ),
  );
}

class _FakePhotoCubit extends PhotoCubit {
  _FakePhotoCubit(PhotoState initial) : super(_NullRepo(), _NullSettingsRepo()) {
    emit(initial);
  }
}

class _NullRepo implements PhotoRepository {
  @override
  Future<List<PhotoEntity>> getPhotos() async => [];
}

class _NullSettingsRepo implements DisplaySettingsRepository {
  @override
  Future<DisplaySettings> getSettings() async => const DisplaySettings();

  @override
  Future<void> saveSettings(DisplaySettings settings) async {}
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
    testWidgets('does not overflow in a 200x200 slot (loading)', (
      tester,
    ) async {
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

    testWidgets('uses Image.file for file:// URLs', (tester) async {
      final state = PhotoLoaded(
        photos: [
          PhotoEntity(
            id: 1,
            filename: 'local.jpg',
            mimeType: 'image/jpeg',
            fetchedAt: DateTime(2026, 5, 1),
            imageUrl: 'file:///home/pi/photos/local.jpg',
          ),
        ],
        currentIndex: 0,
      );
      await tester.pumpWidget(_wrapWithState(state));
      // Image.file is used when scheme is file://
      expect(find.byType(Image), findsWidgets);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final hasFileImage = images.any((img) => img.image is FileImage);
      expect(hasFileImage, isTrue);
    });

    testWidgets('uses Image.network for http:// URLs', (tester) async {
      final state = PhotoLoaded(
        photos: [
          PhotoEntity(
            id: 1,
            filename: 'remote.jpg',
            mimeType: 'image/jpeg',
            fetchedAt: DateTime(2026, 5, 1),
            imageUrl: 'https://example.com/remote.jpg',
          ),
        ],
        currentIndex: 0,
      );
      await tester.pumpWidget(_wrapWithState(state));
      expect(find.byType(Image), findsWidgets);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final hasNetworkImage = images.any((img) => img.image is NetworkImage);
      expect(hasNetworkImage, isTrue);
      final network = images.firstWhere((img) => img.image is NetworkImage);
      expect((network.image as NetworkImage).headers, isNull);
    });
  });
}
